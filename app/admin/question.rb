ActiveAdmin.register Question do
  belongs_to :section
  permit_params :id, :title, :description, :extra, :embed, :widget_type, :raw_options,
      :raw_labels, :criteria, :default_value, :minimum_units, :maximum_units,
      :step, :unit_amount, :unit_name, :required, :revenue, :maxlength, :size,
      :rows, :cols, :placeholder, :_destroy, :_create, :_update

  controller do
    skip_authorize_resource :only => :index

    def parsed_params_for_key(key)
      params_for_key = permitted_params[:question][key]
      params_for_key.split("\n") if params_for_key
    end

    before_create do |question|
      question_params = permitted_params[:question]
      question.options = OptionsParser.parse(
        raw_options: question_params[:raw_options],
        widget_type: question_params[:widget_type],
        minimum_units: question_params[:minimum_units],
        maximum_units: question_params[:maximum_units],
        step: question_params[:step]
      )
      question.labels = LabelsParser.parse(
        raw_labels: question_params[:raw_labels],
        widget_type: question_params[:widget_type]
      )
    end
  end

  form do |f|
    f.inputs t('legend.question') do
      unless f.object.new_record?
        f.input :_destroy, as: :boolean
      end

      f.input :title
      f.input :description, as: :text, input_html: {rows: 4}
      f.input :extra, as: :text, input_html: {rows: 2}
      f.input :embed, as: :text, input_html: {rows: 2}
      f.input :widget_type, collection: Widget::TYPES.map{|w| [t(w, scope: :widget), w]}
      f.input :raw_options, as: :text, input_html: {rows: 5}
      f.input :raw_labels, as: :text, input_html: {rows: 5}
      f.input :criteria, collection: f.object.section.criterion
    end

    inputs t('legend.widget'), class: 'inputs inline' do
      f.input :default_value, input_html: {size: 8}
      f.input :minimum_units, input_html: {size: 8}
      f.input :maximum_units, input_html: {size: 8}
      f.input :step, input_html: {size: 8}
    end

    inputs t('legend.fiscal'), class: 'inputs inline' do
      f.input :unit_amount, as: :string, input_html: {size: 8}
      f.input :unit_name, input_html: {size: 18}
    end

    inputs t('legend.html'), class: 'inputs inline' do
      f.input :required
      f.input :revenue
      f.input :maxlength, as: :string, input_html: {size: 4}
      f.input :size, as: :string, input_html: {size: 4}
      f.input :rows, as: :string, input_html: {size: 4}
      f.input :cols, as: :string, input_html: {size: 4}
      f.input :placeholder, input_html: {size: 18}
    end

    f.input :position, as: :hidden
    f.actions
  end
end
