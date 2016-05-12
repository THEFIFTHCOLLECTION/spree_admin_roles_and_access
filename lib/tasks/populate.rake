namespace :spree_roles do
  namespace :permissions do
    task :populate => :environment do
      admin = Spree::Role.where(name: 'admin').first_or_create!
      user = Spree::Role.where(name: 'user').first_or_create!
      manager = Spree::Role.where(name: 'manager').first_or_create!
      stock_management = Spree::Role.where(name: 'stock management').first_or_create!
      order_management = Spree::Role.where(name: 'order management').first_or_create!

      user.is_default = true
      user.save!

      admin_permissions = Spree::Permission.where(title: 'can-manage-all', priority: 0).first_or_create!
      default_permissions = Spree::Permission.where(title: 'default-permissions', priority: 1).first_or_create!

      [ 'orders','addresses','shipments','return_authorizations', 'products','variants','images','taxons','taxonomies','prices', 'option_types','option_values','product_properties','properties','prototypes', 'stock_items','promotions', 'promotion_actions', 'promotion_rules', 'sales','sale_batches','sale_items', 'sellers'].sort.each do |model|
        Spree::Permission.where(title: "can-manage-spree/#{model}", priority: 2).first_or_create!
      end

      [ 'products', 'orders', 'addresses','shipments','return_authorizations', 'users' ].sort.each do |model|
        Spree::Permission.where(title: "can-index-spree/#{model}", priority: 3).first_or_create!
        Spree::Permission.where(title: "can-read-spree/#{model}", priority: 3).first_or_create!
        Spree::Permission.where(title: "can-create-spree/#{model}", priority: 3).first_or_create!
        Spree::Permission.where(title: "can-update-spree/#{model}", priority: 3).first_or_create!
      end

      # TODO: don't know how to add permissions specifically to controllers, these dont work
      # reports_access = Spree::Permission.where(title: 'can-manage-spree/admin/reports', priority: 3).first_or_create!
      # configuration_access = Spree::Permission.where(title: 'can-manage-spree/admin/general_settings/edit', priority: 3).first_or_create!

      to_build = []

      admin.permissions = [ admin_permissions ]
      user.permissions = [ default_permissions ]

      manager.permissions = [ default_permissions ]
      to_build << { manager =>
        {
          "can" =>
            {
              "manage" =>
                ['orders', 'addresses', 'shipments','return_authorizations', 'products', 'option_types', 'properties', 'prototypes', 'taxons', 'promotions', 'promotion_actions', 'promotion_rules', 'sales', 'sale_batches', 'sellers'],
              "index" => ['users'],
              "read" => ['users'],
              "create" => ['users'],
              "update" => ['users'],
            }
        }
      }

      stock_management.permissions =  [ default_permissions ]
      to_build << { stock_management =>
        {
          "can" =>
            {
              "index"  => ['products'],
              "read"   => ['products'],
              "create" => ['products'],
              "update" => ['products'],
              "manage" => ['product_properties', 'variants', 'option_values', 'stock_items', 'images', 'sale_items' ] },
        }
      }

      order_management.permissions =  [ default_permissions ]
      to_build << { order_management =>
        {
          "can" =>
            {
              "index"  => ['orders'],
              "read"   => ['orders', 'addresses', 'shipments', 'return_authorizations'],
              "create" => ['orders', 'addresses', 'shipments', 'return_authorizations'],
              "update" => ['orders', 'addresses', 'shipments', 'return_authorizations' ]
            }
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
