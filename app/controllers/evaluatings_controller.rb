class EvaluatingsController < ApplicationController
  def index
    not authenticate_user(true, false, Adviser.all.map{|adviser| adviser.user}) and return
    if is_current_user_admin?
      @evaluatings = Evaluating.all
    elsif is_current_user_adviser?
      @evaluatings = Adviser.adviser?(current_user.id).get_advised_teams_evaluatings
    else
      raise ActionController::RoutingError.new(t('application.path_not_found_message'))
    end
    @page_title = t('.page_title')
  end

  def new
    not authenticate_user(true, false, Adviser.all.map{|adviser| adviser.user}) and return
    @evaluating = Evaluating.new
    adviser = Adviser.adviser?(current_user.id)
    if is_current_user_admin?
      teams = Team.all
    elsif adviser
      teams = adviser.teams
    end
    @page_title = t('.page_title')
    render locals: {teams: teams}
  end

  def create
    not authenticate_user(true, false, Adviser.all.map{|adviser| adviser.user}) and return
    @evaluating = Evaluating.new(get_evaluating_params)
    if create_or_update_evaluation_relationship
      redirect_to evaluatings_path,
                  flash: {success: t('.success_message',
                                     entity1_name: @evaluating.evaluator.team_name,
                                     entity2_name: @evaluating.evaluated.team_name)}
    else
      redirect_to new_evaluating_path,
                  flash: {danger: t('.failure_message',
                                    error_messages: @evaluating.errors.full_messages.join(', '))}
    end
  end

  def edit
    @evaluating = Evaluating.find(params[:id])
    not authenticate_user(true, false, get_evaluating_permitted_users) and return
    if is_current_user_admin?
      teams = Team.all
    elsif (adviser = is_current_user_adviser?)
      teams = adviser.teams
    end
    @page_title = t('.page_title')
    render locals: {teams: teams}
  end

  def update
    @evaluating = Evaluating.find(params[:id])
    not authenticate_user(true, false, get_evaluating_permitted_users) and return
    @evaluating.assign_attributes(get_evaluating_params)
    if create_or_update_evaluation_relationship
      redirect_to evaluatings_path,
                  flash: {success: t('.success_message',
                                     entity1_name: @evaluating.evaluator.team_name,
                                     entity2_name: @evaluating.evaluated.team_name)}
    else
      redirect_to edit_evaluating_path(@evaluating),
                  flash: {danger: t('.failure_message',
                                    error_messages: @evaluating.errors.full_messages.join(', '))}
    end
  end

  def destroy
    @evaluating = Evaluating.find(params[:id])
    not authenticate_user(true, false, get_evaluating_permitted_users) and return
    if @evaluating.destroy
      redirect_to evaluatings_path,
                  flash: {success: t('.success_message',
                                     entity1_name: @evaluating.evaluator.team_name,
                                     entity2_name: @evaluating.evaluated.team_name)}
    else
      redirect_to evaluatings_path,
                  flash: {danger: t('.failure_message',
                                    error_messages: @evaluating.errors.full_messages.join(', '))}
    end
  end

  private
  def get_evaluating_params
    params.require(:evaluating).permit(:evaluated_id, :evaluator_id)
  end

  def get_evaluating_permitted_users
    evaluating_users = []
    adviser = Adviser.adviser?(current_user.id) if current_user
    if adviser and @evaluating.evaluated.adviser_id == adviser.id
      evaluating_users.append(adviser.user)
    end
    evaluating_users
  end

  def create_or_update_evaluation_relationship
    adviser = Adviser.adviser?(current_user.id)
    if is_current_user_admin?
      return @evaluating.save ? @evaluating : nil
    elsif not adviser.nil?
      if (@evaluating.evaluated and @evaluating.evaluated.adviser_id == adviser.id) and
        (@evaluating.evaluator and @evaluating.evaluator.adviser_id == adviser.id)
        return @evaluating.save ? @evaluating : nil
      end
    end
    nil
  end
end
