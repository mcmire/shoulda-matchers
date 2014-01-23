module Shoulda
  module Matchers
    module ActiveModel
      # The `validate_uniqueness_of` matcher tests usage of the
      # `validates_uniqueness_of` validation. It first checks for an existing
      # instance of your model in the database, creating one if necessary. It
      # then takes a new record and asserts that it fails validation if the
      # attribute or attributes you've specified in the validation are set to
      # values which are the same as those of the pre-existing record (thereby
      # failing the uniqueness check).
      #
      #     class Post < ActiveRecord::Base
      #       validates_uniqueness_of :permalink
      #     end
      #
      #     # RSpec
      #     describe Post do
      #       it { should validate_uniqueness_of(:permalink) }
      #     end
      #
      #     # Test::Unit
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:permalink)
      #     end
      #
      # #### Caveat
      #
      # This matcher works a bit differently than other matchers. As noted
      # before, it will create an instance of your model if one doesn't already
      # exist. Sometimes this step fails, especially if you have database-level
      # restrictions on any attributes other than the one which is unique. In
      # this case, the solution is to **create a record manually** before you
      # call `validate_uniqueness_of`.
      #
      # For example, say you have the following migration and model:
      #
      #     class CreatePosts < ActiveRecord::Migration
      #       def change
      #         create_table :posts do |t|
      #           t.string :title
      #           t.text :content, null: false
      #         end
      #       end
      #     end
      #
      #     class Post < ActiveRecord::Base
      #       validates :title, uniqueness: true
      #     end
      #
      # You may be tempted to test the model like this:
      #
      #     describe Post do
      #       it { should validate_uniqueness_of(:title) }
      #     end
      #
      # However, running this test will fail with something like:
      #
      #     Failures:
      #
      #       1) Post should require case sensitive unique value for title
      #          Failure/Error: it { should validate_uniqueness_of(:title) }
      #          ActiveRecord::StatementInvalid:
      #            SQLite3::ConstraintException: posts.content may not be NULL: INSERT INTO "posts" ("title") VALUES (?)
      #
      # To fix this, you'll need to write this instead:
      #
      #     describe Post do
      #       it do
      #         Post.create!(content: 'Here is the content')
      #         should validate_uniqueness_of(:title)
      #       end
      #     end
      #
      # Or, if you're using
      # [FactoryGirl](http://github.com/thoughtbot/factory_girl) and you have a
      # `post` factory defined which automatically sets `content`, you can say:
      #
      #     describe Post do
      #       it do
      #         FactoryGirl.create(:post)
      #         should validate_uniqueness_of(:title)
      #       end
      #     end
      #
      # #### Qualifiers
      #
      # ##### with_message
      #
      # Use `with_message` if you are using a custom validation message.
      #
      #     class Post < ActiveRecord::Base
      #       validates_uniqueness_of :title, message: 'Please choose another title'
      #     end
      #
      #     # RSpec
      #     describe Post do
      #       it do
      #         should validate_uniqueness_of(:title).
      #           with_message('Please choose another title')
      #       end
      #     end
      #
      #     # Test::Unit
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:title).
      #         with_message('Please choose another title')
      #     end
      #
      # ##### scoped_to
      #
      # Use `scoped_to` to test usage of the `:scope` option. This asserts that
      # a new record fails validation if not only the primary attribute is not
      # unique, but the scoped attributes are not unique either.
      #
      #     class Post < ActiveRecord::Base
      #       validates_uniqueness_of :slug, scope: :user_id
      #     end
      #
      #     # RSpec
      #     describe Post do
      #       it { should validate_uniqueness_of(:slug).scoped_to(:journal_id) }
      #     end
      #
      #     # Test::Unit
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:slug).scoped_to(:journal_id)
      #     end
      #
      # ##### case_insensitive
      #
      # Use `case_insensitive` to test usage of the `:case_sensitive` option
      # with a false value. This asserts that the uniquable attributes fail
      # validation even if their values are a different case than corresponding
      # attributes in the pre-existing record.
      #
      #     class Post < ActiveRecord::Base
      #       validates_uniqueness_of :key, case_sensitive: false
      #     end
      #
      #     # RSpec
      #     describe Post do
      #       it { should validate_uniqueness_of(:key).case_insensitive }
      #     end
      #
      #     # Test::Unit
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:key).case_insensitive
      #     end
      #
      # ##### allow_nil
      #
      # Use `allow_nil` to assert that the attribute allows nil.
      #
      #     class Post < ActiveRecord::Base
      #       validates_uniqueness_of :author_id, allow_nil: true
      #     end
      #
      #     # RSpec
      #     describe Post do
      #       it { should validate_uniqueness_of(:author_id).allow_nil }
      #     end
      #
      #     # Test::Unit
      #     class PostTest < ActiveSupport::TestCase
      #       should validate_uniqueness_of(:author_id).allow_nil
      #     end
      #
      # @return [ValidateUniquenessOfMatcher]
      #
      def validate_uniqueness_of(attr)
        ValidateUniquenessOfMatcher.new(attr)
      end

      # @private
      class ValidateUniquenessOfMatcher < ValidationMatcher
        include Helpers

        def initialize(attribute)
          super(attribute)
          @options = {}
        end

        def scoped_to(*scopes)
          @options[:scopes] = [*scopes].flatten
          self
        end

        def with_message(message)
          @expected_message = message
          self
        end

        def case_insensitive
          @options[:case_insensitive] = true
          self
        end

        def allow_nil
          @options[:allow_nil] = true
          self
        end

        def description
          result = "require "
          result << "case sensitive " unless @options[:case_insensitive]
          result << "unique value for #{@attribute}"
          result << " scoped to #{@options[:scopes].join(', ')}" if @options[:scopes].present?
          result
        end

        def matches?(subject)
          @subject = subject.class.new
          @expected_message ||= :taken
          set_scoped_attributes &&
            validate_everything_except_duplicate_nils? &&
            validate_after_scope_change? &&
            allows_nil?
        end

        private

        def allows_nil?
          if @options[:allow_nil]
            ensure_nil_record_in_database
            allows_value_of(nil, @expected_message)
          else
            true
          end
        end

        def existing_record
          @existing_record ||= first_instance
        end

        def first_instance
          @subject.class.first || create_record_in_database
        end

        def ensure_nil_record_in_database
          unless existing_record_is_nil?
            create_record_in_database(nil_value: true)
          end
        end

        def existing_record_is_nil?
          @existing_record.present? && existing_value.nil?
        end

        def create_record_in_database(options = {})
          if options[:nil_value]
            value = nil
          else
            value = 'a'
          end

          @subject.class.new.tap do |instance|
            instance.__send__("#{@attribute}=", value)
            if has_secure_password?
              instance.password = 'password'
              instance.password_confirmation = 'password'
            end
            instance.save(validate: false)
          end
        end

        def has_secure_password?
          @subject.class.ancestors.map(&:to_s).include?('ActiveModel::SecurePassword::InstanceMethodsOnActivation')
        end

        def set_scoped_attributes
          if @options[:scopes].present?
            @options[:scopes].all? do |scope|
              setter = :"#{scope}="
              if @subject.respond_to?(setter)
                @subject.__send__(setter, existing_record.__send__(scope))
                true
              else
                @failure_message = "#{class_name} doesn't seem to have a #{scope} attribute."
                false
              end
            end
          else
            true
          end
        end

        def validate_everything_except_duplicate_nils?
          if @options[:allow_nil] && existing_value.nil?
            create_record_without_nil
          end

          disallows_value_of(existing_value, @expected_message)
        end

        def create_record_without_nil
          @existing_record = create_record_in_database
        end

        def validate_after_scope_change?
          if @options[:scopes].blank?
            true
          else
            all_records = @subject.class.all
            @options[:scopes].all? do |scope|
              previous_value = all_records.map(&scope).max

              # Assume the scope is a foreign key if the field is nil
              previous_value ||= correct_type_for_column(@subject.class.columns_hash[scope.to_s])

              next_value =
                if previous_value.respond_to?(:next)
                  previous_value.next
                elsif previous_value.respond_to?(:to_datetime)
                  previous_value.to_datetime.next
                else
                  previous_value.to_s.next
                end

              @subject.__send__("#{scope}=", next_value)

              if allows_value_of(existing_value, @expected_message)
                @subject.__send__("#{scope}=", previous_value)

                @failure_message_when_negated <<
                  " (with different value of #{scope})"
                true
              else
                @failure_message << " (with different value of #{scope})"
                false
              end
            end
          end
        end

        def correct_type_for_column(column)
          if column.type == :string
            '0'
          elsif column.type == :datetime
            DateTime.now
          elsif column.type == :uuid
            SecureRandom.uuid
          else
            0
          end
        end

        def class_name
          @subject.class.name
        end

        def existing_value
          value = existing_record.__send__(@attribute)
          if @options[:case_insensitive] && value.respond_to?(:swapcase!)
            value.swapcase!
          end
          value
        end
      end
    end
  end
end
