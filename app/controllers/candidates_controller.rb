class CandidatesController < ApplicationController
  def index
    @candidates = Candidate.all
  end

  def show
    @candidate = Candidate.find_by(id: params[:id])
    return if @candidate

    head :not_found
  end

  def new
    @candidate = Candidate.new
  end

  def create
    @candidate = Candidate.new(candidate_params)
    return render :new, status: :unprocessable_entity unless @candidate.save

    redirect_to @candidate 
  end

  def edit
    @candidate = Candidate.find_by(id: params[:id])
    return if @candidate

    head :not_found
  end

  def update
    @candidate = Candidate.find_by(id: params[:id])

    return head :not_found unless @candidate

    return render :edit, status: :unprocessable_entity unless @candidate.update(candidate_params)

    redirect_to @candidate
  end

  def destroy
    @candidate = Candidate.find_by(id: params[:id])

    return head :not_found unless @candidate

    @candidate.destroy
    redirect_to candidates_path
  end

  private

  def candidate_params
    params.require(:candidate).permit(
      :name,
      :candidate_num,
      :election_id,
      :office_id,
      :party_id
    )
  end
end
