class PartiesController < ApplicationController
  def index
    @parties = Party.all
  end

  def show
    @party = Party.find_by(id: params[:id])
    return if @party

    head :not_found
  end

  def new
    @party = Party.new
  end

  def create
    @party = Party.new(party_params)
    return render :new, status: :unprocessable_entity unless @party.save

    redirect_to @party
  end

  def edit
    @party = Party.find_by(id: params[:id])
    return if @party

    head :not_found
  end

  def update
    @party = Party.find_by(id: params[:id])

    return head :not_found unless @party

    return render :edit, status: :unprocessable_entity unless @party.update(party_params)

    redirect_to @party
  end

  def destroy
    @party = Party.find_by(id: params[:id])
    return head :not_found unless @party

    @party.destroy
    redirect_to parties_path
  end

  private

  def party_params
    params.require(:party).permit(
      :name,
      :party_number,
      :abbreviation,
      :description
    )
  end
end
