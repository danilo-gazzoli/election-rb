class ElectionsController < ApplicationController
  def index
    @elections = Election.all
  end

  def show
    @election = Election.find_by(id: params[:id])
    unless @election 
      return head :not_found
    end
  end

  def new
    @election = Election.new
  end

  def create
    @election = Election.new(election_params)
    unless @election.save 
      return render :new, status: :unprocessable_entity 
    end

    redirect_to @election
  end

  def edit
    @election = Election.find_by(id: params[:id])
    unless @election 
      return head :not_found
    end
  end

  def update
    @election = Election.find_by(id: params[:id])

    unless @election 
      return head :not_found
    end

    unless @election.update(election_params) 
      return render :edit, status: :unprocessable_entity
    end

    redirect_to @election
  end

  def destroy
    @election = Election.find_by(id: params[:id])
    unless @election 
      return head :not_found
    end

    @election.destroy
    redirect_to elections_path
  end

  private

  def election_params 
    params.require(:election).permit(
      :title,
      :description,
      :status,
      :start_time,
      :end_time,
      :election_day)
  end
end
