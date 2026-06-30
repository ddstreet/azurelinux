
[Return to index](./index.md)

# Top-level objects

The TOML parsing will result in a hierarchy of objects that describe the entire project and specify exactly how to perform the processing and transformation of the upstream dist-git repositories into local modified dist-git directories.

## project

This required object field contains general configuration for the project, and is [described here](./project.md).

## distros

This required object field contains specific configuration for distributions. The object contains any number of object fields, each of which correspond to a specific distribution name, and whose value is an object [as described here](./distros.md).

## components

This required object field contains specific configuration for components (i.e. source packages). The object contains any number of object fields, each of which correspond to a single component name, and whose value is an object [as described here](./components.md).

## component_groups

This optional object field contains general configuration for components (i.e. source packages). The object contains any number of object fields, each of which correspond to a single group name, and whose value is an object [as described here](./component_groups.md).
