class ResponsesController < ApplicationController
  prepend_before_filter :find_questionnaire # run before #set_locale

  # http://broadcastingadam.com/2012/07/advanced_caching_part_1-caching_strategies/
  caches_action :new, cache_path: ->(c) do
    record = @questionnaire.responses.build
    cache_key record
  end
  caches_action :show, cache_path: ->(c) do
    record = @questionnaire.responses.find params[:id]
    cache_key record
  end

  def new
    @response = @questionnaire.responses.build initialized_at: Time.now.utc, newsletter: true, subscribe: true
    build_questionnaire
    fresh_when @questionnaire, public: true
  end

  def show
    @response = @questionnaire.responses.find params[:id]
    build_questionnaire
    fresh_when @response, public: true
  end

  def create
    @response = @questionnaire.responses.build params[:response]
    @response.answers = params.select{|k,_| k[/\A[a-f0-9]{24}\z/]}
    @response.ip      = request.ip
    @response.save! # There shouldn't be errors.
    Notifier.thank_you(@response).deliver if @response.email.present?
    redirect_to @response, notice: t(:create_response)
  end

private

  def find_questionnaire
    @questionnaire = Questionnaire.where(authorization_token: params[:token]).first if params[:token]
    @questionnaire ||= Questionnaire.find_by_domain(request.host)
    @questionnaire ||= Questionnaire.last if Rails.env.development?
    redirect_to t('app.product_url') if @questionnaire.nil?
  end

  def set_locale
    I18n.locale = locale_from_record(@questionnaire) || super
  end

  def build_questionnaire
    @groups = @questionnaire.sections.budgetary.group_by(&:group)
    @maximum_difference = [
      @questionnaire.maximum_amount.abs,
      @questionnaire.minimum_amount.abs,
    ].max
  end

  def cache_key(record)
    parts = [record.cache_key]
    parts << params[:token] if params[:token] # use a different cache for token access
    parts.join '-'
  end
end
