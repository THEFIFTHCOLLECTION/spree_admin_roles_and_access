namespace :spree_roles do
  namespace :permissions do
    task :populate => :environment do
      admin = Spree::Role.where(name: 'admin').first_or_create!
      user = Spree::Role.where(name: 'user').first_or_create!
      manager = Spree::Role.where(name: 'manager').first_or_create!
      customer_service = Spree::Role.where(name: 'customer service').first_or_create!
      warehouse = Spree::Role.where(name: 'warehouse').first_or_create!

      user.is_default = true
      user.save!

      admin_permissions = Spree::Permission.where(title: 'can-manage-all', priority: 0).first_or_create!
      default_permissions = Spree::Permission.where(title: 'default-permissions', priority: 1).first_or_create!

      [ 'orders','addresses','payments','creditcard_payments','shipments','shipping_categories', 'tax_categories','credit_cards','return_authorizations', 'products','variants','images','taxons','taxonomies','prices', 'option_types','option_values','product_properties','properties','prototypes', 'stock_items','stock_locations','inventory_unit', 'promotions', 'promotion_actions', 'promotion_rules', 'sales','sale_batches','sale_items', 'users','sellers','account_sales_records', 'preferences'].each do |model|
          Spree::Permission.where(title: "cannot-read-spree/#{model}", priority: 2).first_or_create!
          Spree::Permission.where(title: "cannot-index-spree/#{model}", priority: 2).first_or_create!
          Spree::Permission.where(title: "cannot-update-spree/#{model}", priority: 2).first_or_create!
          Spree::Permission.where(title: "cannot-create-spree/#{model}", priority: 2).first_or_create!

          Spree::Permission.where(title: "can-manage-spree/#{model}", priority: 3).first_or_create!

          Spree::Permission.where(title: "can-read-spree/#{model}", priority: 4).first_or_create!
          Spree::Permission.where(title: "can-index-spree/#{model}", priority: 4).first_or_create!
          Spree::Permission.where(title: "can-update-spree/#{model}", priority: 4).first_or_create!
          Spree::Permission.where(title: "can-create-spree/#{model}", priority: 4).first_or_create!
        end

      reports_model = Spree::Permission.where(title: 'can-read-spree/admin/reports', priority: 3).first_or_create!

      to_build = []

      admin.permissions = [ admin_permissions ]
      user.permissions = [ default_permissions ]

      manager.permissions = [ default_permissions ]
      to_build << { manager =>
        {"can" =>
          { "manage" =>
            ['products', 'variants','prices','orders','addresses','payments','line_items','stock_items', 'option_types', 'taxonomies', 'taxons', 'images', 'product_properties', 'stock_locations']
          }
        }
      }

      customer_service.permissions =  [ default_permissions ]
      to_build << { customer_service =>
        {
          "can" =>
            { "manage" => ['orders'] },
          "cannot" =>
            { "create" => ['orders'] }
        }
      }

      warehouse.permissions = [ default_permissions ]
      to_build << { warehouse =>
        {
          "can" =>
            { "manage" =>
              ['products','stock_locations','orders',
                'stock_items']
            },
          "cannot" =>
            { "create" => ['orders'] }
        }
      }

      # build the permissions here
      to_build.each do |role_grp|
        role_grp.each_pair do |role, perm_grps|
          perm_grps.each_pair do |cancan, perms|
            perms.each_pair do |action, models|
              models.each do |model|
                role.permissions << Spree::Permission.find_by(title: "#{cancan}-#{action}-spree/#{model}")
              end
            end
          end
        end
      end

    end
  end
end
