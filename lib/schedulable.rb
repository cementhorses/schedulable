module CementHorses #:nodoc:
  module Schedulable #:nodoc:
    def self.included(base)
      base.extend ClassMethods
    end

    # +schedulable+ adds simple "schedulability" to your +ActiveRecord+ models
    
    # Example:
    #
    #   class NewsItem < ActiveRecord::Base
    #     schedulable :published_at, :archived_at
    #   end
    #
    #   news_item.published_at = 5.minutes.from_now
    #   news_item.published? # => false
    #   news_item.scheduled? # => true
    #   news_item.published_at = 5.minutes.ago
    #   news_item.published? # => true
    #   news_item.scheduled? # => false
    module ClassMethods
      # Options:
      #
      # * +start+ - the timestamp column that defines the scheduled start.
      #   It can also be set as the first argument, rather than a hash value.
      #   Example: <tt>schedulable :start => :started_at</tt> or
      #   <tt>schedulable :started_at</tt>.
      # * +end+ - the timestamp column that defines the scheduled end. It can
      #   likewise appear as a second argument. Example: <tt>schedulable
      #   :start => :started_at, :end => :ended_at</tt> or <tt>schedulable
      #   :started_at, :ended_at</tt>.
      # * +end_required+ - validates the presence of an +end+ value (defaults
      #   to +false+).
      def schedulable(*args)
        options         = args.extract_options!
        options[:start] = args.shift if options[:start].blank? && !args.empty?
        options[:end]   = args.shift if options[:end].blank? && !args.empty?

        configuration = { :start => :published_at, :end => false }
        configuration.update options

        methods = <<-end_eval
          def scheduled?(field = "#{configuration[:start]}")
            !send(field).blank? && send(field) > Time.now
          end
        end_eval
        
        if self.class.respond_to? 'named_scope'
          methods += <<-end_eval
            named_scope :scheduled, :conditions => ['`#{configuration[:start]}` > ?', Time.now]
          end_eval
        end
        
        if configuration[:end]
          methods += <<-end_eval
            def #{configuration[:start].to_s.gsub(/_(at|on)$/, '')}?
              !#{configuration[:start]}.blank? && #{configuration[:start]} < Time.now && (!#{configuration[:end]}.blank? ? #{configuration[:end]} > Time.now : true)
            end

            def #{configuration[:end].to_s.gsub(/_(at|on)$/, '')}?
              !#{configuration[:end]}.blank? && #{configuration[:end]} < Time.now
            end
          end_eval
          
          if self.class.respond_to? 'named_scope'
            methods += <<-end_eval
              named_scope :#{configuration[:start].to_s.gsub(/_(at|on)$/, '')}, :conditions => ['`#{configuration[:start]}` < ? AND (`#{configuration[:end]}` IS NULL OR `#{configuration[:end]}` > ?)', *[Time.now] * 2]
              named_scope :#{configuration[:end].to_s.gsub(/_(at|on)$/, '')}, :conditions => ['`#{configuration[:end]}` < ?', Time.now]
            end_eval
          end
        else
          methods += <<-end_eval
            def #{configuration[:start].to_s.gsub(/_(at|on)$/, '')}?
              !#{configuration[:start]}.blank? && #{configuration[:start]} < Time.now
            end
          end_eval
          
          if self.class.respond_to? 'named_scope'
            methods += <<-end_eval
              named_scope :#{configuration[:start].to_s.gsub(/_(at|on)$/, '')}, :conditions => ['`#{configuration[:start]}` < ?', Time.now]
            end_eval
          end
        end

        if configuration[:end]
          methods += <<-end_eval
            validate :schedulability_issues

            protected

              def schedulability_issues
                if !#{configuration[:end]}.blank? && #{configuration[:start]} && #{configuration[:end]} <= #{configuration[:start]}
                  errors.add :#{configuration[:end]}, "needs to come later than the #{configuration[:end].to_s.gsub(/_(at|on)$/, 'ing')} date"
                elsif !#{configuration[:end]}.blank? && #{configuration[:start]}.blank?
                  errors.add :#{configuration[:end]}, "not allowed without a #{configuration[:start].to_s.gsub(/_(at|on)$/, 'ing')} date"
                end
              end
          end_eval
        end

        if configuration[:end_required]
          methods += <<-end_eval
            public

            validate :#{configuration[:end]}_required

            protected

              def #{configuration[:end]}_required
                if #{configuration[:end]}.blank? && !#{configuration[:start]}.blank?
                  errors.add :#{configuration[:end]}, "required with a #{configuration[:start].to_s.gsub(/_(at|on)$/, '')} date"
                end
              end
          end_eval
        end

        class_eval methods, __FILE__, __LINE__
      end
    end
  end
end