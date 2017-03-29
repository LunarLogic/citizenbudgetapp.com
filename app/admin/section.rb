ActiveAdmin.register Section do
  belongs_to :questionnaire
  permit_params :title, :group, :description, :extra, :embed, :criterion_as_list

  # CanCan has trouble with embedded documents, so we may need to load and
  # authorize resources manually. In this case, we will authorize against
  # the top-level document.
  # @see https://github.com/ryanb/cancan/issues/319
  #
  # Since sections are scoped to the parent questionnaire, we don't necessarily
  # need to use #accessible_by to enforce constraints.
  #
  # https://github.com/ryanb/cancan/wiki/Controller-Authorization-Example
  controller do
    skip_authorize_resource :only => :index

    def index
      authorize! :show, parent
      index!
    end
  end

  index do
    column :title
    column :group do |s|
      t(s.group, scope: :group) if s.group?
    end
    column :questions do |s|
      s.questions.count
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :title
      f.input :group, collection: Section::GROUPS.map{|g| [t(g, scope: :group), g]}
      f.input :description, as: :text, input_html: {rows: 3}
      f.input :extra, as: :text, input_html: {rows: 3}
      f.input :embed, as: :text, input_html: {rows: 3}
      f.input :criterion_as_list, as: :text, label: 'Criterion', input_html: {rows: 10}
    end

    f.actions
  end

  show do
    attributes_table do
      row :title
      row :group do |s|
        t(s.group, scope: :group) if s.group?
      end
      row :description do |s|
        RDiscount.new(s.description).to_html.html_safe if s.description?
      end
      row :extra do |s|
        RDiscount.new(s.extra).to_html.html_safe if s.extra?
      end
      row :embed do |s|
        markdown_embed(s.embed) if s.embed?
      end
      row :criterion do |s|
        ul do
          s.criterion.each do |criteria|
            li do
              criteria
            end
          end
        end
      end
      row :questions do |s|
        if s.questions.present?
          ul(class: authorized?(:update, s) ? 'sortable' : '') do
            s.questions.each_with_index do |q,index|
              present q do |q|
                li(id: dom_id(q)) do
                  if authorized?(:update, q)
                    i(class: 'icon-move')
                  end
                  text_node link_to_if authorized?(:update, q), q.name, edit_admin_questionnaire_section_path(s.questionnaire, s, anchor: "section_questions_attributes_#{index}__destroy_input")
                end
              end
            end
          end
        end

        if authorized?(:create, Question)
          div link_to t(:new_question), [:new, :admin, s, :question], class: 'button'
        end
      end
    end
  end

  member_action :sort, method: :post do
    resource.questions.each do |q|
      q.set :position, params[:question].index(q.id.to_s)
    end
    render nothing: true, status: 204
  end
end
