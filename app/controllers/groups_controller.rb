class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show update destroy ]

  # GET /groups
  def index
    @groups = Group.all

    render json: @groups
  end

  # GET /groups/1
  def show
    render json: @group
  end

  # POST /groups
  def create
    # ActionDispatch::Request가 JSON을 파싱하는 것을 확인하기 위한 로깅
    divider = "=" * 50
    puts divider
    puts "request: #{request}"
    puts "params: #{params}"
    puts "Content-Type: #{request.content_type}"
    puts "Raw body: #{request.raw_post}"
    puts "Parsed params: #{params.inspect}"
    puts "Request format: #{request.format}"
    puts divider
    
    @group = Group.new(group_params)

    if @group.save
      render json: @group, status: :created, location: @group
    else
      render json: @group.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /groups/1
  def update
    if @group.update(group_params)
      render json: @group
    else
      render json: @group.errors, status: :unprocessable_content
    end
  end

  # DELETE /groups/1
  def destroy
    @group.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Group.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def group_params
      params.expect(group: [ :name ])
    end
end
