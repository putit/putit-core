class OrderController < SecureController
  get '/' do
    param :status,                String, in: ReleaseOrder.statuses.map(&:first), required: false, raise: true
    param :upcoming,              Boolean, required: false, raise: true
    param :start_date,            Date, required: false, raise: true
    param :end_date,              Date, required: false, raise: true
    param :include,               String, is: 'release_order_results', required: false, raise: true
    param :includeClosedReleases, Boolean, required: false, raise: true
    param :q,                     String, required: false, raise: true

    if params[:upcoming] == true
      orders = ReleaseOrder.upcoming
    elsif
      orders = ReleaseOrder.all
    end

    included_relations = []
    included_relations = params[:include].split(',') if params[:include]

    if params['includeClosedReleases'].to_s != 'true'
      release_status_eq_open = Release.arel_table[:status].eq(Release.statuses[:open])
      orders = orders.joins(:release).where(release_status_eq_open)
    end

    if params.include?('start_date')
      orders = orders.where('start_date >= ?', params['start_date'])
    end

    if params.include?('end_date')
      orders = orders.where('start_date < ?', params['end_date'])
    end

    orders = orders.where(status: params['status']) if params.include?('status')

    if params[:q]
      q = params[:q].downcase
      release_name_matches_q = Release.arel_table[:name].lower.matches("%#{q}%")
      release_order_name_matches_q = ReleaseOrder.arel_table[:name].lower.matches("%#{q}%")

      orders = orders.joins(:release)
                     .where(
                       release_name_matches_q.or(release_order_name_matches_q)
                     )
    end

    orders.to_json(include: included_relations)
  end
end
