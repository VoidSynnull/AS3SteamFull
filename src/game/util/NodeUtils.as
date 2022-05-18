package game.util
{
	import flash.utils.describeType;
	
	import ash.core.Component;
	import ash.core.Entity;
	import ash.core.Node;

	public class NodeUtils
	{
		public function NodeUtils()
		{
		}
		
		/**
		 * Create a node 
		 * @param entity
		 * @param nodeClass
		 * @return 
		 */
		public static function createNode( entity:Entity, nodeClass:Class ):Node
		{
			// create node from entity and add to state
			var node:Node = new nodeClass();
			var variables : XMLList = describeType( nodeClass ).factory.variable;
			for each ( var atom:XML in variables )
			{
				if ( atom.@name != "entity" && atom.@name != "previous" && atom.@name != "next" && atom.@name != "optional" )
				{
					var componentClass : Class = ClassUtils.getClassByName( atom.@type );
					var componentName:String = atom.@name.toString();
					
					node[componentName] = entity.get( componentClass );
					/***************** wrb - reference counting for components ********************/
					if(node[componentName]) { Component(node[componentName]).nodesAddedTo++; }
					/***************** wrb - reference counting for components ********************/
				}
			}
			node.entity = entity;
			return node;
		}
		
		public static function createNodeList( entity:Entity, nodeClass:Class ):void
		{
			
		}
		
	}
}