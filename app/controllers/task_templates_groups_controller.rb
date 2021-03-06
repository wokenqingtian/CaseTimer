class TaskTemplatesGroupsController < ApplicationController
	before_action :authenticate_user!
	before_action :require_not_super_user

	def new
		@case = Case.find(params[:case_id])
		@group = TaskTemplatesGroup.new(case_id: params[:case_id])
		@group.task_templates.build
	end

	def create
		@case = Case.find(params[:case_id])
		@group = TaskTemplatesGroup.new(task_templates_group_params)
		@group.case = @case
		@group.user = current_user

		if @group.save!
			# binding.pry
			round = Grade.where(user_id: current_user, case_id: @case).order("created_at").last.round + 1
			Grade.create!(user: current_user, case: @case, group: @group, finish: false, round: round, round_time: 0)
			# binding.pry
			@group.templates.each do |template|
				Task.create!(round: round, task_template_id: template.id, title: template.title)
			end

			favor = Favor.find_by(user: current_user, case: @case)
			favor.group = @group
			favor.save!

			redirect_to case_path(@case)
		else
			render :new
		end
	end

	private

	def task_templates_group_params
		params.require(:task_templates_group).permit(:task_templates_attributes => [:id, :title, :_destroy])
	end

	def require_not_super_user
		if current_user.is_super_admin?
			redirect_to :back
		end
	end


end
