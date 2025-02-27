class OfficesController < ApplicationController
  def index
    @offices = Office.all
  end

  def show
    @office = Office.find_by(id: params[:id])
    return if @office

    head :not_found
  end

  def new
    @office = Office.new
  end

  def create
    @office = Office.new(office_params)
    return render :new, status: :unprocessable_entity unless @office.save

    redirect_to @office
  end

  def edit
    @office = Office.find_by(id: params[:id])
    return if @office

    head :not_found
  end

  def update
    @office = Office.find_by(id: params[:id])

    return head :not_found unless @office

    return render :edit, status: :unprocessable_entity unless @office.update(office_params)

    redirect_to @office
  end

  def destroy
    @office = Office.find_by(id: params[:id])
    return head :not_found unless @office

    @office.destroy
    redirect_to offices_path

  end

  private

  def office_params
    params.require(:office).permit(
      :name,
      :num_of_seats,
      :needs_vice,
      :election_id
    )
  end

end
