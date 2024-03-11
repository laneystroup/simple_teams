class Teams::InvitationsController < TeamsController
  before_action :set_team
  before_action :set_invitation, except: %i[ new create index]

  def new
    authorize! :create, @team.invitations.new
    @service_object = Teams::InvitationForms::CreateCombo.new(@team, current_user)
  end

  def create
    authorize! :create, @team.invitations.new
    @service_object = Teams::InvitationForms::CreateCombo.new(@team, current_user)

    respond_to do |format|
      if @service_object.perform(new_service_object_params)
        format.html { redirect_to team_path(@team), notice: "Invitations were successfully created." }
        format.json { render :show, status: :created, location: @invitation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @invitation.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :update, @invitation
    @service_object = Teams::InvitationForms::Update.new(@invitation, current_user)
  end

  def update
    authorize! :update, @invitation
    @service_object = Teams::InvitationForms::Update.new(@invitation, current_user)

    respond_to do |format|
      if @service_object.perform(service_object_params)
        format.html { redirect_to team_path(@team), notice: "Invitation was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @invitation.errors, status: :unprocessable_entity }
      end
    end

  end

  def resend
    authorize! :update, @invitation
    @invitation.resend_invitation_notification

    respond_to do |format|
      format.html { redirect_to team_path(@team), notice: "Invitation was successfully resent." }
      format.json { head :no_content }
    end
  end

  def destroy
    authorize! :destroy, @invitation
    invitation_id = @invitation.id
    invitation_email_address = @invitation.email_address
    @invitation.destroy

    Teams::Invitations::DestroyedNotification.with(
      :team_id => @team.id,
      :invitation_id => invitation_id,
      :user_id => current_user.id,
      :team_name => @team.name,
      :invitation_name => invitation_email_address,
      :user_name => current_user.full_name
    ).deliver_later(@team.members)

    respond_to do |format|
      format.html { redirect_to team_path(@team), notice: "Invitation was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def new_service_object_params
      params.require(:teams_invitation_forms_create_combo).permit(:role, :single_vs_multiple, :email_address, :accessible_email_addresses, :select2_email_addresses => [])
    end

    def service_object_params
      params.require(:teams_invitation_forms_update).permit(:email_address, :role)
    end

    def set_team
      @team = Teams::Team.find(params[:team_id])
    end

    def set_invitation
      @invitation = Teams::Invitation.find(params[:id])
    end
end