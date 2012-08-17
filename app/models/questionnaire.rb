require 'mail'

class Questionnaire
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Mongoid::MultiParameterAttributes

  MODES = %w(services taxes)

  belongs_to :organization, index: true
  embeds_many :sections
  has_many :responses
  embeds_one :google_api_authorization, autobuild: true
  mount_uploader :logo, ImageUploader
  mount_uploader :title_image, ImageUploader

  # Basic
  field :title, type: String
  field :locale, type: String
  field :starts_at, type: Time
  field :ends_at, type: Time
  field :time_zone, type: String
  field :domain, type: String
  field :email_required, type: Boolean

  # Mode
  field :mode, type: String

  # Appearance
  field :logo, type: String
  field :title_image, type: String
  field :introduction, type: String
  field :description, type: String

  # Thank-you email
  field :reply_to, type: String
  field :thank_you_template, type: String

  # Third-party integration
  field :google_analytics, type: String # tracking code
  field :google_analytics_profile, type: String # table ID
  field :twitter_screen_name, type: String
  field :twitter_text, type: String
  field :twitter_share_text, type: String
  field :facebook_app_id, type: String
  field :authorization_token, type: String

  # Image uploaders
  field :logo_width, type: Integer
  field :logo_height, type: Integer
  field :title_image_width, type: Integer
  field :title_image_height, type: Integer

  attr_protected :authorization_token, :logo_width, :logo_height

  index domain: 1

  validates_presence_of :title, :organization_id, :mode
  validates_inclusion_of :mode, in: MODES, allow_blank: true
  validates_inclusion_of :locale, in: Locale.available_locales, allow_blank: true
  validates_inclusion_of :time_zone, in: ActiveSupport::TimeZone.all.map(&:name), allow_blank: true
  validates_length_of :twitter_text, maximum: 140, allow_blank: true
  validates_length_of :twitter_share_text, maximum: 140, allow_blank: true
  validates_uniqueness_of :domain, allow_blank: true
  validates :reply_to, email: true, allow_blank: true
  validate :ends_at_must_be_greater_than_starts_at
  validate :domain_must_be_active
  validate :reply_to_must_be_valid

  before_validation :sanitize_domain
  before_save :add_domain
  before_create :set_authorization_token

  scope :current, where(:starts_at.ne => nil, :ends_at.ne => nil, :starts_at.lte => Time.now, :ends_at.gte => Time.now)
  scope :future, where(:starts_at.ne => nil, :starts_at.gt => Time.now)
  scope :past, where(:ends_at.ne => nil, :ends_at.lt => Time.now)
  scope :active, where(:ends_at.ne => nil, :ends_at.gte => Time.now)

  # @param [String] domain a domain name
  # @return [Questionnaire,nil] a questionnaire whose domain name matches
  # @note No two active questionnaires should have the same domain.
  def self.find_by_domain(domain)
    domain && current.any_in(domain: [domain, sanitize_domain(domain)]).first
  end

  # @return [Integer] the number of responses by date in the local time zone
  def count_by_date
    # new Date() always parses the date into the current time zone. getTime()
    # returns the number of milliseconds since epoch. getTimezoneOffset()
    # returns the offset in minutes. In case we can't assume that MongoDB is
    # running in UTC, we add the local time zone offset.
    responses.map_reduce(%Q{
      function () {
        var date = new Date(this.created_at.getTime() + this.created_at.getTimezoneOffset() * 60000 + #{offset} * 1000);
        emit({year: date.getFullYear(), month: date.getMonth() + 1, day: date.getDate()}, {count: 1});
      }
    }, %Q{
      function (key, values) {
        var result = {count: 0};
        values.forEach(function (value) {
          result.count += value.count;
        });
        return result;
      }
    }).out(inline: true)
  end

  # @return [Integer] the median number of seconds to complete the questionnaire
  def time_to_complete
    times = responses.map{|response|
      response.created_at - response.initialized_at
    }.select{|time|
      time < 3600 # if longer than an hour, probably left tab open in background
    }.sort

    middle = times.size / 2

    if times.size.zero?
      0
    elsif times.size.odd?
      times[middle]
    else
      (times[middle - 1] + times[middle]) / 2.0
    end
  end

  # @return [Integer] the number of days elapsed
  def days_elapsed
    (today - starts_on).to_i
  end

  # @return [Date] the consultation's start date in its time zone
  def starts_on
    starts_at.in_time_zone(time_zone).to_date
  end

  # @return [Date] the consultation's end date in its time zone
  def ends_on
    ends_at.in_time_zone(time_zone).to_date
  end

  # @return [Date] the current date in the consultation's time zone
  def today
    if time_zone?
      Time.now.in_time_zone(time_zone).to_date
    else
      Date.today
    end
  end

  # @return [Integer] the time zone offset in seconds
  # @note If the consultation crosses a clock shift, the offset will be
  #   incorrect for the final days of the consultation.
  def offset
    if starts_at? && time_zone?
      starts_at.in_time_zone(time_zone).utc_offset # respects DST
    else
      0
    end
  end

  def domain_url
    domain? && "http://#{domain}"
  end

  def current?
    starts_at? && ends_at? && starts_at <= Time.now && Time.now <= ends_at
  end

  def future?
    starts_at? && starts_at > Time.now
  end

  def started?
    starts_at? && starts_at <= Time.now
  end

  def active?
    ends_at? && ends_at >= Time.now
  end

  def past?
    ends_at? && ends_at < Time.now
  end

  # @return [Float] the largest surplus possible
  def maximum_amount
    sections.budgetary.reduce(0) do |sum,section|
      sum + section.questions.reduce(0) do |sum,q|
        if section.group == 'revenue'
          sum + (q.maximum_amount || 0)
        else
          sum - (q.minimum_amount || 0)
        end
      end
    end
  end

  # @return [Float] the largest deficit possible
  def minimum_amount
    sections.budgetary.reduce(0) do |sum,section|
      sum + section.questions.reduce(0) do |sum,q|
        if section.group == 'revenue'
          sum + (q.minimum_amount || 0)
        else
          sum - (q.maximum_amount || 0)
        end
      end
    end
  end

  # @return [Array] a list of CSV headers
  def csv_headers
    @headers ||= begin
      headers = %w(id ip created_at time_to_complete email name)
      if sections.nonbudgetary.none? # backwards compatibility
        headers += %w(postal_code gender age comments newsletter subscribe)
      end
      headers
    end
  end

private

  # Removes the protocol and trailing slash, if present.
  # @param [String] domain a domain name
  # @return [String] the domain without the protocol or trailing slash
  def self.sanitize_domain(domain)
    domain.sub(%r{\A(https?://)?(www\.)?}, '').sub(%r{/\z}, '')
  end

  def sanitize_domain
    if domain?
      self.domain = self.class.sanitize_domain domain
    end
  end

  def ends_at_must_be_greater_than_starts_at
    if starts_at? && ends_at? && starts_at > ends_at
      errors.add :ends_at, I18n.t('errors.messages.ends_at_must_be_greater_than_starts_at')
    end
  end

  def domain_must_be_active
    if domain? && !domain[/\A[a-z]+\.(citizenbudget|budgetcitoyen)\.com\z/] # @todo Remove hardcode.
      begin
        Socket.gethostbyname domain
      rescue SocketError
        errors.add :domain, I18n.t('errors.messages.domain_must_be_active')
      end
    end
  end

  def reply_to_must_be_valid
    if reply_to?
      begin
        address = Mail::Address.new Mail::Address.new(reply_to).address
        unless (address.domain && address.__send__(:tree).domain.dot_atom_text.elements.size > 1 rescue false)
          errors.add :reply_to, I18n.t('errors.messages.reply_to_must_be_valid')
        end
      rescue Mail::Field::ParseError
        errors.add :reply_to, I18n.t('errors.messages.reply_to_must_be_valid')
      end
    end
  end

  def set_authorization_token
    loop do
      self.authorization_token = SecureRandom.base64(15).tr('+/=lIO0', 'pqrsxyz')
      break unless self.class.where(authorization_token: authorization_token).first
    end
  end

  # Adds the questionnaire's domain to the app's custom domains list on Heroku.
  # @todo protect app and www subdomains of citizenbudget/budgetcitoyen
  def add_domain
    if HerokuClient.configured? && domain_changed?
      domains = HerokuClient.list_domains

      if domain_was.present?
        queue = [domain_was]
        if domain_was.split('.').size == 2
          queue << "www.#{domain_was}"
        end
        queue.each do |d|
          if domains.include? d
            HerokuClient.remove_domain d
          end
        end
      end

      if domain.present?
        queue = [domain]
        if domain.split('.').size == 2
          queue << "www.#{domain}"
        end
        queue.each do |d|
          unless domains.include? d
            HerokuClient.add_domain d
          end
        end
      end
    end
  end
end
