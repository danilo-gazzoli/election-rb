# frozen_string_literal: true

class ElectionsController < ApplicationController
  def index
    @elections = Election.all
  end

  def show
    @election = Election.find_by(id: params[:id])
    return if @election

    head :not_found
  end

  def new
    @election = Election.new
  end

  def create
    @election = Election.new(election_params)
    return render :new, status: :unprocessable_entity unless @election.save

    redirect_to @election
  end

  def edit
    @election = Election.find_by(id: params[:id])
    return if @election

    head :not_found
  end

  def update
    @election = Election.find_by(id: params[:id])

    return head :not_found unless @election

    return render :edit, status: :unprocessable_entity unless @election.update(election_params)

    redirect_to @election
  end

  def destroy
    @election = Election.find_by(id: params[:id])
    return head :not_found unless @election

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
      :election_day
    )
  end
end
