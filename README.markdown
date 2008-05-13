Schedulable
===========

"Schedulability" to your models, as simple as 1, 2,

    schedulable

Just install.

    $ script/plugin install git://github.com/cementhorses/schedulable.git

Options
-------

Calling `schedulable` automatically hooks a few methods to a `published_at`
column:

- `scheduled?` (`true` if the item is scheduled to be published but isn't yet)
- `published?` (`true` if the item is published)

The real power is when expiration is a question

    schedulable :end => :archived_at
    
or

    schedulable :published_at, :archived_at

does a little more:

- `scheduled? :archived_at` (`true` if `archived_at` is set in the future)
- `archived?` (`true` if the item has been archived)

with a note:

- `published?` returns `false` when `archived?` returns `true`.


It's all semantic sugar:

    schedulable :activated_at, :terminated_at, :end_required => true

therefore creates:

- `activated?`
- `terminated?`

And that last option? It just adds a validation requiring the `:end` to be set
if the `:start` is.

We also have your validations taken care of.


Rails 2.1 Is Extra Sweet
------------------------

`named_scope` support means a few extra methods.

    class NewsItem < ActiveRecord::Base
      schedulable :published_at, :archived_at
    end

Now you can scope it out:

- `NewsItem.scheduled` returns news items scheduled to be published
- `NewsItem.published` returns published news items
- `NewsItem.archived` returns archived news items

Copyright (c) 2008 Cement Horses, released under the MIT license.