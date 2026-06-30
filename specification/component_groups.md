
[Return to top-level objects](./objects.md)

# component_groups

The component_groups object provides configuration for one or more components (i.e. source packages). It contains any number object fields, with free-format keys corresponding to the name of each group, and fields as described below.

- description
  This optional string field provides a human-readable description of what the group is used for.
  
- components
  This optional array field contains string component names this group should be applied to.
  
- default_component_config
  This optional object field contains [component configuration](./components.md) that should be inherited by each of this group's components.
