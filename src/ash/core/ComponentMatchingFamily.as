package ash.core
{
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	

	/**
	 * The default class for managing a NodeList. This class creates the NodeList and adds and removes
	 * nodes to/from the list as the entities and the components in the engine change.
	 * 
	 * It uses the basic entity matching pattern of an entity system - entities are added to the list if
	 * they contain components matching all the public properties of the node class.
	 */
	public class ComponentMatchingFamily implements IFamily
	{
		private var nodes : NodeList;
		private var entities : Dictionary;
		private var nodeClass : Class;
		private var components : Dictionary;
		private var nodePool : NodePool;
		private var engine : Engine;
		private var _optionalComponents:Array = [];

		/**
		 * The constructor. Creates a ComponentMatchingFamily to provide a NodeList for the
		 * given node class.
		 * 
		 * @param nodeClass The type of node to create and manage a NodeList for.
		 * @param engine The engine that this family is managing teh NodeList for.
		 */
		public function ComponentMatchingFamily( nodeClass : Class, engine : Engine )
		{
			this.nodeClass = nodeClass;
			this.engine = engine;
			init();
		}

		/**
		 * Initialises the class. Creates the nodelist and other tools. Analyses the node to determine
		 * what component types the node requires.
		 */
		private function init() : void
		{
			nodes = new NodeList();
			entities = new Dictionary();
			components = new Dictionary();
			nodePool = new NodePool( nodeClass, components );
			
			nodePool.dispose( nodePool.get() ); // create a dummy instance to ensure describeType works.

			var variables : XMLList = describeType( nodeClass ).factory.variable;
			for each ( var atom:XML in variables )
			{
				if ( atom.@name != "entity" && atom.@name != "previous" && atom.@name != "next" && atom.@name != "optional" )
				{
					var componentClass : Class = getDefinitionByName( atom.@type ) as Class;
					components[componentClass] = atom.@name.toString();
				}
			}
			
			var node:* = new nodeClass();
			
			if(node.hasOwnProperty("optional"))
			{
				_optionalComponents = node.optional.slice();
			}
		}
		
		/**
		 * The nodelist managed by this family. This is a reference that remains valid always
		 * since it is retained and reused by Systems that use the list. i.e. we never recreate the list,
		 * we always modify it in place.
		 */
		public function get nodeList() : NodeList
		{
			return nodes;
		}

		/**
		 * Called by the engine when an entity has been added to it. We check if the entity should be in
		 * this family's NodeList and add it if appropriate.
		 */
		public function newEntity( entity : Entity ) : void
		{
			addIfMatch( entity );
		}
		
		/**
		 * Called by the engine when a component has been added to an entity. We check if the entity is not in
		 * this family's NodeList and should be, and add it if appropriate.
		 */
		public function componentAddedToEntity( entity : Entity, componentClass : Class ) : void
		{
			if(components[componentClass])
			{
				addIfMatch( entity );
			}
		}
		
		/**
		 * Called by the engine when a component has been removed from an entity. We check if the removed component
		 * is required by this family's NodeList and if so, we check if the entity is in this this NodeList and
		 * remove it if so.
		 */
		public function componentRemovedFromEntity( entity : Entity, componentClass : Class ) : void
		{
			//If it's a component we care about.
			if(components[componentClass])
			{
				var node:Node = entities[entity];
				//And we have a node for it.
				if(node)
				{
					//If it's optional, clean up the node's reference to it.
					if(_optionalComponents.indexOf(componentClass) != -1 )
					{
						var component:Component = node[components[componentClass]];
						if(component)
						{
							component.nodesAddedTo--;
							node[components[componentClass]] = null;
						}
					}
					//Otherwise remove the entity from the list.
					else
					{
						removeEntity( entity );
					}
				}
			}
		}
		
		/**
		 * Called by the engine when an entity has been removed from it. We check if the entity is in
		 * this family's NodeList and remove it if so.
		 */
		public function removeEntity( entity : Entity ) : void
		{
			this.removeIfMatch(entity);
		}
		
		/**
		 * If the entity is not in this family's NodeList, tests the components of the entity to see
		 * if it should be in this NodeList and adds it if so.
		 */
		private function addIfMatch( entity : Entity ) : void
		{
			var componentClass : *;
			var node : Node;
			
			if( !entities[entity] )
			{
				for ( componentClass in components )
				{
					if ( !entity.has( componentClass ) && _optionalComponents.indexOf(componentClass) == -1)
					{
						return;
					}
				}
				node = nodePool.get();
				node.entity = entity;
				for ( componentClass in components )
				{
					node[components[componentClass]] = entity.get( componentClass );
					/***************** wrb - reference counting for components ********************/
					if(node[components[componentClass]]) { Component(node[components[componentClass]]).nodesAddedTo++; }
					/***************** wrb - reference counting for components ********************/
				}
				entities[entity] = node;
				nodes.add( node );
			}
			else if(_optionalComponents.length > 0)
			{
				for each(componentClass in _optionalComponents)
				{
					node = entities[entity];
					var component:Component = node[components[componentClass]];
					if(!component)
					{
						component = entity.get( componentClass );
						/***************** wrb - reference counting for components ********************/
						if(component)
						{
							node[components[componentClass]] = component;
							component.nodesAddedTo++;
						}
						/***************** wrb - reference counting for components ********************/
					}
					
				}
			}
		}
		
		/**
		 * Removes the entity if it is in this family's NodeList.
		 */
		private function removeIfMatch( entity : Entity ) : void
		{
			var node:Node = entities[entity];
			if(node)
			{
				/***************** wrb - reference counting for components ********************/
				for each(var componentName:String in components )
				{
					var component:Component = node[componentName];
					if(component)
					{
						component.nodesAddedTo--;
					}
				}
				/***************** wrb - end reference counting for components ********************/
				
				delete entities[entity];
				nodes.remove( node );
				if( engine.updating )
				{
					nodePool.cache( node );
					engine.updateComplete.add( releaseNodePoolCache );
				}
				else
				{
					nodePool.dispose( node );
				}
			}
		}
		
		/**
		 * Releases the nodes that were added to the node pool during this engine update, so they can
		 * be reused.
		 */
		private function releaseNodePoolCache() : void
		{
			engine.updateComplete.remove( releaseNodePoolCache );
			nodePool.releaseCache();
		}
		
		/**
		 * Removes all nodes from the NodeList.
		 */
		public function cleanUp() : void
		{
			for( var node : Node = nodes.head; node; node = node.next )
			{
				delete entities[node.entity];
			}
			nodes.removeAll();
		}
	}
}
