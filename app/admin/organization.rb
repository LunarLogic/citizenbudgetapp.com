ActiveAdmin.register Organization do
  permit_params :name

  index do
    column :name
    column :questionnaires do |o|
      link_to_if authorized?(:read, Questionnaire), o.questionnaires.count, [:admin, :questionnaires]
    end
    actions
  end

  form partial: 'form'

  show do
    attributes_table do
      row :name
      row :questionnaires do |o|
        if o.questionnaires.present?
          ul do
            o.questionnaires.each do |q|
              li auto_link q
            end
          end
        end
        if authorized?(:create, Questionnaire)
          div link_to t(:new_questionnaire), new_admin_questionnaire_path(organization_id: resource.id), class: 'button'
        end
      end
    end
  end
end
