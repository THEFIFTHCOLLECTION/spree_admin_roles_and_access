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

      admin-permissions = Spree::Permission.where(title: 'can-manage-all', priority: 0).first_or_create!
      default-permissions = Spree::Permission.where(title: 'default-permissions', priority: 1).first_or_create!

      [ 'orders','products','variants','images','taxons','taxonomies',
        'option_types','option_values','product_properties','properties',
        'stock_items','stock_locations','promotions','sales','users','sellers','account_sales_records'].each do |model|
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

      reports-model = Spree::Permission.where(title: 'can-read-spree/admin/reports', priority: 3).first_or_create!

      to_build = []

      admin.permissions = [ admin-permissions ]
      user.permissions = [ default-permissions ]

      manager.permissions = [ default-permissions ]
      to_build << { manager =>
        {"can" =>
          [{ "manage" =>
            ['products', 'orders', 'stocks', 'option_types', 'taxonomies', 'images', 'product_properties', 'stocks']
          }]
        }
      }

      customer_service.permissions =  [ default-permissions ]
      to_build << { customer_service =>
        {
          "can" =>
            [{ "manage" => ['orders'] }],
          "cannot" =>
            [{ "create" => ['orders'] }]
        }
      }

      warehouse.permissions = [ default-permissions ]
      to_build << { warehouse =>
        {
          "can" =>
            [{ "manage" =>
              ['products','stock_locations','orders',
                'stock_items']
            }],
          "cannot" =>
            [{ "create" => ['orders'] }]
        }
      }

      # build the permissions here
      to_build.each_pair do |role, perm_grps|
        perm_grps.each_pair do |cancan, perms|
          perms.each_pair do |model, actions|
            actions.each do |action|
              role.permissions << Spree::Permission.find_by(title: "#{cancan}-#{action}-spree/#{model}")
            end
          end
        end
      end

    end
  end
end
