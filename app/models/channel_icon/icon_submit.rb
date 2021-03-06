class ChannelIcon::IconSubmit
  require 'csv'
  require 'ipaddr'
  def initialize
    # Statistics
    @stats = {atsc: 0, callsign: 0, dvb: 0, total: 0, xmltvid: 0}
  end
  def stats
    return @stats
  end
  def submit(csv, ip_in)
    # TODO: Blocked ip / icon etc support
    ip = IPAddr.new(ip_in)
    # each CSV row contains
    # iconid, name, xmltvid, callsign, transportid, atscmajor, atscminor, networkid, serviceid
    CSV.parse("#{csv}") do |query|
      iconid = query[0]; name = query[1]; xmltvid = query[2]; callsign = query[3]; tsid = query[4]
      atscmajor = query[5]; atscminor = query[6]; netid = query[7]; serviceid = query[8]
      @stats[:total] += 1
      if !callsign.empty?
        begin
          icon = ChannelIcon::PendingCallsign.find_or_initialize_by(icon_id: iconid, callsign: callsign, channame: name, ip: ip.to_i)
          if icon.new_record?
            @stats[:callsign] += 1
          end
          if icon.valid?
            icon.save
          end
        rescue ActiveRecord::RecordNotUnique => e
          Rails.logger.info "  Already know about #{name} (Callsign #{callsign}), icon_id: #{iconid} from ip #{ip.to_s} (#{ip.to_i})"
        end
      end
      if !xmltvid.empty?
        begin
          icon = ChannelIcon::PendingXmltvid.find_or_initialize_by(icon_id: iconid, xmltvid: xmltvid, channame: name, ip: ip.to_i)
          if icon.new_record?
            @stats[:xmltvid] += 1
          end
          if icon.valid?
            icon.save
          end
        rescue ActiveRecord::RecordNotUnique => e
          Rails.logger.info "  Already know about #{name} (xmltvid #{xmltvid}), icon_id: #{iconid} from ip #{ip.to_s} (#{ip.to_i})"
        end
      end
      if (tsid.to_i > 0 && netid.to_i > 0 && serviceid.to_i > 0)
        begin
          icon = ChannelIcon::PendingDvb.find_or_initialize_by(icon_id: iconid, transportid: tsid, networkid: netid,
            serviceid: serviceid, channame: name, ip: ip.to_i)
          if icon.new_record?
            @stats[:dvb] += 1
          end
          if icon.valid?
            icon.save
          end
        rescue ActiveRecord::RecordNotUnique => e
          Rails.logger.info "  Already know about #{name} (DVB #{netid}:#{tsid}:#{serviceid}), icon_id: #{iconid} from ip #{ip.to_s} (#{ip.to_i})"
        end
      end
      if (tsid.to_i > 0 && atscmajor.to_i > 0 && atscminor.to_i > 0)
        begin
          icon = ChannelIcon::PendingAtsc.find_or_initialize_by(icon_id: iconid, transportid: tsid, major_chan: atscmajor,
            minor_chan: atscminor, channame: name, ip: ip.to_i)
          if icon.new_record?
            @stats[:atsc] += 1
          end
          if icon.valid?
            icon.save
          end
        rescue ActiveRecord::RecordNotUnique => e
          Rails.logger.info "  Already know about #{name} (ATSC #{tsid}:#{atscmajor}:#{atscminor}), icon_id: #{iconid} from ip #{ip.to_s} (#{ip.to_i})"
        end
      end
    end
    return @stats
  end
end
