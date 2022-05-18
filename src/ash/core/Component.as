package ash.core 
{
	import flash.utils.getQualifiedClassName;

	/**
	 * The abstract base class for all Poptropica components. The Ash framework
	 * doesn't define an abstract Component class, but Poptropica does in order
	 * to implement reference counting, which facilitates the unloading of rig animations.
	 * @author billy
	 */
	public class Component
	{
		/**
		 * Incremented and decremented by Entity.add/Entity.remove.  Tracks how many total entities are using this component.
		 * 
		 * @see ash.core.Entity
		 */
		public var componentManagers:Vector.<Entity> = new Vector.<Entity>();
		
		/**
		 * Static constant for debugging Components when they're destroyed. If true, destroy() will output
		 * a formmatted String of Component information.
		 */
		private static const DEBUG:Boolean = false;
		
		/**
		 * Each time a component is added to a <code>Node</code>, the <code>ComponentMatchingFamily</code>,
		 * which is responsible for managing <code>NodeLists</code>,
		 * increments its <code>added</code> by one. Conversely, it is decremented by one each time it is removed
		 * from an <code>Entity</code>. This functionality is not present in the original Ash framework -
		 * it has been added by the Poptropica development team.
		 * @default	Zero
		 * 
		 * @see ash.core.ComponentMatchingFamily
		 * @see game.data.animation.Animation
		 */		
		public var nodesAddedTo:int = 0;
		
		public function Component()
		{
			
		}
		
		public function destroy():void
		{
			if(DEBUG)
			{
				var string:String = "Component:" + getQualifiedClassName(this).split("::")[1];
				
				while(string.length < 30) string += " ";
				
				string += "Entities: " + this.componentManagers.length;
				
				while(string.length < 45) string += " ";
				
				string += "Nodes: " + this.nodesAddedTo;
				
				trace(string);
			}
		}
	}
}