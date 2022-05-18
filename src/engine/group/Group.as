package engine.group
{
	/**
	 * The base class for groups.
	 * 
	 * A group is used to associate common Systems, Entities or UIElements.  Groups are added with GroupManager which tracks all systems, entities 
	 * and elements it adds and cleans them up when the Group itself is removed.
	 */
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.ShellApi;
	import engine.managers.GroupManager;
	import engine.util.Command;
	
	import game.ui.elements.UIElement;
	
	import org.osflash.signals.Signal;

	public class Group
	{
		public static const INCLUDE_CHILDREN:Boolean		= true;
		public static const DONT_INCLUDE_CHILDREN:Boolean	= false;
		public static const WAIT:Boolean					= true;
		public static const DONT_WAIT:Boolean				= false;
		
		public function Group()
		{			
			ready = new Signal(Group);
			removed = new Signal(Group);
		}
		
		/**
		 * Cleans up the group.  This should not be called directly...groups should be added and removed with 'remove' which will call destroy after
		 * all associated systems, uielements and entities are removed by GroupManager.
		 */
		public function destroy():void
		{
			removed.dispatch(this);
			ready.removeAll();
			removed.removeAll();
			ready = null;
			removed = null;
			
			_groupEntity = null;
		}
		
		protected function groupReady():void
		{
			_isReady = true;
			this.ready.dispatch(this);
		}
		
		/**
		 * Called by GroupManager when this group has been added, injected, and in the case of DisplayGroups, had its init() function called.
		 */
		public function added():void
		{
			
		}
		
		public function pause(pauseChildGroups:Boolean = true, waitForUpdateComplete:Boolean = false):void
		{
			if(waitForUpdateComplete)
			{
				this.systemManager.updateComplete.addOnce(Command.create(pause, pauseChildGroups, false));
				return;
			}
			
			_paused = true;
			
			if(pauseChildGroups && this.children)
			{
				for(var n:uint = 0; n < this.children.length; n++)
				{
					Group(this.children[n]).pause(true, false);
				}
			}
		}
		
		public function unpause(unpauseChildGroups:Boolean = true, waitForUpdateComplete:Boolean = false):void
		{
			if(waitForUpdateComplete)
			{
				this.systemManager.updateComplete.addOnce(Command.create(unpause, unpauseChildGroups, false));
				return;
			}
			
			_paused = false;
			
			if(unpauseChildGroups && this.children)
			{
				for(var n:uint = 0; n < this.children.length; n++)
				{
					Group(this.children[n]).unpause(true, false);
				}
			}
		}

		public function get paused():Boolean { return(_paused); }
		
		/**
		 * Shortcut methods to access GroupManager functionality.  Automatically specifies this group and systemManager.
		 */
		public function add():void
		{
			this.groupManager.add(this);
		}
		
		public function remove():void
		{
			this.groupManager.remove(this);
		}
		
		/**
		 * Add a new group as a child of this one.
		 */
		public function addChildGroup(group:Group):Group
		{
			this.groupManager.add(group, this, this.systemManager);
						
			return(group);
		}
		
		/**
		 * Add an entity to the Engine instance associated with this group.
		 */
		public function addEntity(entity:Entity, waitForUpdateComplete:Boolean = false):void
		{
			if(waitForUpdateComplete)
			{
				this.systemManager.updateComplete.addOnce(Command.create(this.groupManager.addEntity, entity, this, this.systemManager));
			}
			else
			{
				this.groupManager.addEntity(entity, this, this.systemManager);
			}
		}
		
		/**
		 * Add a UIElement to this group.
		 */
		public function addElement(element:UIElement):void
		{
			this.groupManager.addElement(element, this);
		}
		
		/**
		 * Add a System to the Engine instance associated with this group.
		 */
		public function addSystem(system:System, priority:uint = 0):System
		{
			this.groupManager.addSystem(system, priority, this, this.systemManager);
			return system;
		}
		
		public function hasSystem(system:Class):Boolean
		{
			return(this.groupManager.hasSystem(system, this));
		}
		
		/**
		 * Remove a group.
		 */
		public function removeGroup(group:Group, waitForUpdateComplete:Boolean = false):void
		{
			if(waitForUpdateComplete)
			{
				this.systemManager.updateComplete.addOnce(Command.create(this.groupManager.remove, group, this.systemManager));
			}
			else
			{
				this.groupManager.remove(group, this.systemManager);
			}
		}
		
		/**
		 * Remove an entity from the Engine instance associated with this group.
		 */
		public function removeEntity(entity:Entity, waitForUpdateComplete:Boolean = false):void
		{
			if(entity)
			{
				if(waitForUpdateComplete)
				{
					this.systemManager.updateComplete.addOnce(Command.create(this.groupManager.removeEntity, entity, this, this.systemManager));
				}
				else
				{
					this.groupManager.removeEntity(entity, this, this.systemManager);
				}
			}
			else
			{
				trace("Error :: Group :: removeEntity : Cannot remove a null entity!");
			}
		}
		
		/**
		 * Remove a ui element from this group.
		 */
		public function removeElement(element:UIElement):void
		{
			this.groupManager.removeElement(element, this);
		}
		
		/**
		 * Remove a system from the Engine instance associated with this group.
		 */
		public function removeSystem(system:System, waitForUpdateComplete:Boolean = false):void
		{
			if(waitForUpdateComplete)
			{
				this.systemManager.updateComplete.addOnce(Command.create(this.groupManager.removeSystem, system, this, this.systemManager));
			}
			else
			{
				this.groupManager.removeSystem(system, this, this.systemManager);
			}
		}
		
		public function removeSystemByClass(systemClass:Class, waitForUpdateComplete:Boolean = false):void
		{
			var system:System = this.getSystem(systemClass);
			if( system )
			{
				removeSystem( system, waitForUpdateComplete );
			}
		}
		
		/**
		 * Get a system associated with this group's Engine instance.
		 */
		public function getSystem(systemClass:Class):System
		{
			return(this.groupManager.getSystem(systemClass, this.systemManager));
		}
		
		/**
		 * Get an Entity associated with this group.
		 */
		public function getEntityById(id:String, parent:Entity = null):Entity
		{
			return(this.groupManager.getEntityById(id, this, parent));
		}
		
		/**
		 * Get an Group from its id.
		 */
		public function getGroupById(id:String, parent:Group = null):Group
		{
			return(this.groupManager.getGroupById(id, parent));
		}
		
		public function get groupEntity():Entity
		{
			if(!_groupEntity)
			{
				_groupEntity = new Entity();
				addEntity(_groupEntity);
			}
			
			return _groupEntity;
		}
		
		/**
		 * Gets a component from the Group's "global" Entity. This is useful for components that don't particularly have
		 * any dependencies to the Entity they're in, such as Tweens. (Timers, etc could also use this setup at some point.)
		 */
		public function getGroupEntityComponent(componentClass:Class):*
		{
			if(!_groupEntity)
			{
				_groupEntity = new Entity();
				addEntity(_groupEntity);
			}
			
			var component:* = _groupEntity.get(componentClass);
			if(!component)
			{
				component = new componentClass();
				_groupEntity.add(component);
			}
			
			return component;
		}
		
		public function get isReady():Boolean { return(_isReady); }
		
		public var ready:Signal;
		public var removed:Signal;
		public var id:String;                 // An optional identifier for this group.  Allows lookup through 'getGroupById'.
		public var children:Vector.<Group>;
		public var parent:Group;
		public var systemManager:Engine;      // The Engine instance that updates the Entities and Systems associated with this group.
		public var removalPending:Boolean = false;
		[Inject]
		public var groupManager:GroupManager;
		[Inject]
		public var shellApi:ShellApi;
		private var _isReady:Boolean = false;
		private var _paused:Boolean = false;
		private var _groupEntity:Entity;
	}
}
