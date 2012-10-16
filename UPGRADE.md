UPGRADE FROM 2.1.x TO 2.2.x
===========================

Upgrading your capifony configuration from **2.1.x** to **2.2.x** is quite easy.
If you don't have a custom `Capfile` file, delete it and recreate it using the
following command:

    capifony .

Important: This is mandatory for both symfony 1.x and Symfony2 projects.

If you have a custom `Capfile` file, you just have to change the way you load
capifony. In capifony 2.1.x and for Symfony2 projects, the line below was used
to load capifony:

    load Gem.find_files('symfony2.rb').first.to_s

You have to replace this line by the following one:

    require 'capifony_symfony2'

For symfony 1.x projects, the line below was used for the same purpose:

    load Gem.find_files('symfony1.rb').first.to_s

You have to replace it by the following line:

    load Gem.find_files('capifony_symfony1.rb').first.to_s

That's all.
