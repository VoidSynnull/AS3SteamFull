package engine.managers
{
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.Manager;
	import engine.components.Id;
	import engine.components.OwningGroup;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Parent;
	import game.ui.elements.UIElement;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	
	import org.as3commons.collections.LinkedList;
	import org.as3commons.collections.framework.ILinkedListIterator;

	public class GroupManager extends Manager
	{
		public function GroupManager(systemManager:Engine)
		{
			_systemManager = systemManager;
		}
				
		/**
		 * Remove all systems and entities from gameSystems, calls destroy() each group and clears all dictionaries.
		 * @param   [systemManager] : The Engine instance to removeAll from.  Defaults to the primary _gameSystemManager instance.
		 */
		public function removeAll(systemManager:Engine = null):void
		{						
			if (systemManager == null)
			{
				systemManager = _systemManager;
			}
			
			for each(var group:Group in _groups)
			{
				if (group != null)
				{
					remove(group);
				}
			}			
			
			systemManager.removeAllEntities();
			systemManager.removeAllSystems();
			
			_systems = null;
			_entities = null;
			_groups = null;
			_elements = null;
		}
		
		/**
		 * Create all dictionarys to track groups and their systems, entities and elements.  Weak keys are used to prevent a group from remaining in memory after all other references to it are gone except the key.
		 */
		public function init():void 
		{
			_systems = new Dictionary(true);
			_entities = new Dictionary(true);
			_groups = new Dictionary(true);
			_elements = new Dictionary(true);
		}
		
		/**
		 * Resize the viewport to a new width and height.  Notify all DisplayGroups of the change in case they need to handle it internally.
		 * @param   viewportWidth : new viewport width
		 * @param   viewportHeight : new viewport height
		 */
		public function resize(viewportWidth:Number, viewportHeight:Number):void
		{
			for each(var group:Group in _groups)
			{
				if (group is DisplayGroup)
				{
					DisplayGroup(group).resize(viewportWidth, viewportHeight);
				}
			}
		}
		
		/**
		 * Create a new group and keep track of its entities, systems, and elements.  This group will be injected with any classes it needs that have been added to the injector.
		 * @param   groupClass : the class to instantiate for this group.
		 * @param   [parent] : Associate another group with this new one.  The new group will be removed when its parent is removed.
		 * @param   [systemsManager] : associate an Engine instance with the group.
		 */
		public function create(groupClass:Class, parent:Group = null, systemManager:Engine = null):Group
		{			
			var newGroup:Group = new groupClass();
			
			this.add(newGroup, parent, systemManager);
			
			return(newGroup);
		}
		
		/**
		 * Add a new group and keep track of its entities, systems, and elements.  This group will be injected with any classes it needs that have been added to the injector.
		 * @param   groupClass : the class to instantiate for this group.
		 * @param   [parent] : Associate another group with this new one.  The new group will be removed when its parent is removed.
		 * @param   [systemsManager] : associate an Engine instance with the group.
		 */
		public function add(group:Group, parent:Group = null, systemManager:Engine = null):void
		{			
			if(_groups == null)
			{
				init();
			}
			
			if(_groups[group] == null)
			{
				this.shellApi.injector.injectInto(group);
				
				_systems[group] = new LinkedList();
				_entities[group] = new LinkedList();
				_elements[group] = new LinkedList();
				
				_groups[group] = group;
				
				if(parent != null)
				{
					if(parent.children == null)
					{
						parent.children = new Vector.<Group>;
					}
					
					parent.children.push(group);
					
					group.parent = parent;
				}
				
				if(systemManager == null)
				{
					systemManager = getSystemManager(parent);
				}
				
				group.systemManager = systemManager;
				// this is set rather than injected so it is available to groups immediately after being added.
				group.groupManager = this;
				
				if(group is DisplayGroup)
				{
					if(DisplayGroup(group).container != null)
					{
						DisplayGroup(group).init(DisplayGroup(group).container);
					}
				}
				// let the group know it has been added.
				group.added();
			}
			else
			{
				trace("Error :: GroupManager :: " + group + " has already been added.");
			}
		}
		
		/**
		 * Remove a group from groupManager and systemsManager.  The group is not fully removed until the systemManager finishes its update.  
		 * 		At that point 'removeReady' cleans up all systems, entities and elements associated with the group and deletes their dictionary entries.
		 *      Any 'children' groups related to this group are also removed.
		 * @param   [group] : the group the entity should be added to, defaults to the current scene.
		 * @param   [systemManager] : The Engine instance to remove this group from.  Defaults to the primary _gameSystemManager instance.
		 */
		public function remove(group:Group, systemManager:Engine = null):void
		{						
			if(group != null)
			{
				this.shellApi.injector.destroyInstance(group);
				
				//_groups[group] = null;
				group.removalPending = true;
				var total:int;
				var index:int;
				
				if (systemManager == null)
				{
					systemManager = getSystemManager(group);
				}
				
				// remove all of this groups children.
				if(group.children != null)
				{
					total = group.children.length;
					
					while(group.children.length > 0)
					{
						remove(group.children[group.children.length-1], systemManager);
					}
				}
				
				// remove this group from it's parents list of child groups if it exists.
				if(group.parent != null)
				{
					if(group.parent.children != null)
					{
						var childIndex:uint = group.parent.children.indexOf(group);
						
						group.parent.children.splice(childIndex, 1);
					}
				}
				
				// wait until a group has cleaned up before removing its systems and entities.
				if(group.removed != null)
				{
					group.removed.addOnce(Command.create(removeReady, systemManager));
				}
				else
				{
					trace("Error :: GroupManager :: Group 'removed' signal is null...attempting to remove group immediately");
					
					// for some reason AdVideoGroup on popups causes an error
					// maybe video on popups should have their own group
					// seems that closing the popup is removing the associated AdVideoGroup
					//if (group is AdVideoGroup)
					if (group.hasOwnProperty('adVideoArray'))
						return;
						
					removeReady(group, systemManager);
				}
				
				if (systemManager.updating)
				{
					// once the game update loop completes, begin removal of the group.
					systemManager.updateComplete.addOnce(group.destroy);
				}
				else
				{
					group.destroy();
				}
			}
		}
		
		/**
		 * Get a reference to a system matching the class type.
		 * @param   system : The system class to lookup.
		 * @param   [systemManager] : The Engine where the system lives.  Defaults to the primary _gameSystemManager instance.
		 */
		public function getSystem(system:Class, systemManager:Engine = null):System
		{						
			if (systemManager == null)
			{
				systemManager = _systemManager;
			}
			
			return(systemManager.getSystem(system));
		}
		
		public function hasSystem(system:Class, group:Group):Boolean
		{
			var systemClass:Class = ClassUtils.getClassByObject(system);
			var systemInstance:System = group.systemManager.getSystem(systemClass);
			
			return(LinkedList(_systems[group]).has(systemInstance));
		}
		
		/**
		 * Add a system to a group
		 * @param   system : the system to be added.
		 * @param   priority : The priority in which this system should update relative to other systems.
		 * @param   [group] : the group the system should be added to, defaults to the current scene.
		 * @param   [systemManager] : The Engine instance which will manage and update this system.  Defaults to the primary _gameSystemManager instance.
		 */
		public function addSystem(system:System, priority:int = 0, group:Group = null, systemManager:Engine = null):System
		{
			if(group == null)
			{
				group = defaultGroup;
			}
			
			if (systemManager == null)
			{
				systemManager = getSystemManager(group);
			}
			
			var systemClass:Class = ClassUtils.getClassByObject(system);
			var currentSystem:System = systemManager.getSystem(systemClass);
			
			if(currentSystem == null)
			{				
				this.shellApi.injector.injectInto(system);
				
				system.group = group;
				system.systemManager = systemManager;
				
				if ( priority > 0 )
				{
					systemManager.addSystem(system, priority);
				}
				else
				{
					systemManager.addSystem(system, system._defaultPriority);
				}
			}
			else
			{
				system = currentSystem;
			}
			
			if(!LinkedList(_systems[group]).has(system))
			{
				LinkedList(_systems[group]).add(system);
			}
			
			return system;
		}
		
		/**
		 * Add an entity to a group
		 * @param   entity  : the entity to add to the group
		 * @param   [group] : the group the entity should be added to, defaults to the current scene.
		 * @param   [systemManager] : The Engine instance where this entity should be added.  Defaults to the primary _gameSystemManager instance.
		 */
		public function addEntity(entity:Entity, group:Group = null, systemManager:Engine = null):void
		{						
			if(group == null)
			{
				group = defaultGroup;
			}
			
			if (systemManager == null)
			{
				systemManager = getSystemManager(group);
			}
			
			entity.group = group;
			entity.add(new OwningGroup(group));
			
			systemManager.addEntity(entity);
			LinkedList(_entities[group]).add(entity);
		}		
		
		/**
		 * Remove a system from a group
		 * @param   system  : the system to remove from the group
		 * @param   [group] : the group the system is part of, defaults to the current scene.
		 * @param   [systemManager] : The Engine instance to remove this system from.  Defaults to the primary _gameSystemManager instance.
		 */
		public function removeSystem(system:System, group:Group = null, systemManager:Engine = null):void
		{						
			if(group == null)
			{
				group = defaultGroup;
			}
			
			if (systemManager == null)
			{
				systemManager = getSystemManager(group);
			}
			
			LinkedList(_systems[group]).remove(system);
			systemManager.removeSystem(system);
			
			var systems:LinkedList;
			
			for each(var nextGroup:Group in _groups)
			{
				systems = _systems[nextGroup];
				systems.remove(system);
			}
			
			system.group = null;
		}
		
		/**
		 * Remove an entity from a group.
		 * @param   entity  : the entity to remove from a group.  All of the entities children will be removed if it has a Children component.
		 * @param   [group] : the group the entity is part of, defaults to the current scene.
		 * @param   [systemManager] : The Engine instance to remove this entity from.  Defaults to the primary _gameSystemManager instance.
		 */
		public function removeEntity(entity:Entity, group:Group = null, systemManager:Engine = null):void
		{		
			if(entity == null)
				return;
			var total:int;
			var childIndex:int;
			
			if(group == null)
			{
				group = getOwningGroup(entity);
			}
			
			if (systemManager == null)
			{
				systemManager = getSystemManager(group);
			}
			
			var children:Children = entity.get(Children);
			var parent:Parent = entity.get(Parent);
			
			// If this entity has children, those should be removed as well.
			if(children != null)
			{
				total = children.children.length;

				for (childIndex = total - 1; childIndex > -1; childIndex--)
				{
					removeEntity(children.children[childIndex], group, systemManager);
				}
			}
			
			// If this entity has a parent with a Children component, this entity should be removed from that list.
			if(parent != null)
			{
				var parentChildren:Children = parent.parent.get(Children);
				
				if(parentChildren != null)
				{
					total = parentChildren.children.length;
					
					for (childIndex = total - 1; childIndex > -1; childIndex--)
					{
						if(parentChildren.children[childIndex] == entity)
						{
							parentChildren.children.splice(childIndex, 1);
							break;
						}
					}
				}
			}
			
			LinkedList(_entities[group]).remove(entity);
			systemManager.removeEntity(entity);
			entity.group = null;
		}			
		
		/**
		 * Add an UIElement to a group
		 * @param   element  : the UIElement to add.
		 * @param   group : the group the element should be added to.  A value must be specified, no default exists for uielements as they'll generally be associated with a UIView rather than the scene default group.
		 */
		public function addElement(element:UIElement, group:Group):void
		{			
			LinkedList(_elements[group]).add(element);
		}		
		
		/**
		 * Remove an UIElement from a group
		 * @param   element  : the UIElement to remove.
		 * @param   group : the group the element is part of.  A value must be specified, no default exists for uielements as they'll generally be associated with a UIView rather than the scene default group.
		 */
		public function removeElement(element:UIElement, group:Group):void
		{			
			if (element != null)
			{
				UIElement(element).destroy();
			}
			
			LinkedList(_elements[group]).remove(element);
		}		
		
		/**
		 * Remove all elements in a group
		 * @param   group : the group the entity is part of.  A value must be specified, no default exists for uielements as they'll generally be associated with a UIView rather than the scene default group.
		 */
		public function removeAllElements(group:Group):void
		{			
			var elements:LinkedList = _elements[group];
			if(elements)
			{
				var iterator:ILinkedListIterator = elements.iterator() as ILinkedListIterator;
				
				while( iterator.hasNext() )
				{
					removeElement(UIElement(iterator.next()), group);
				}
				
				delete _elements[group];
			}
		}
		
		/**
		 * Remove all systems in a group
		 * @param   [group] : the group the system is part of, defaults to the current scene.
		 * @param   [systemManager] : The Engine instance to remove from.  Defaults to the primary _gameSystemManager instance.
		 */
		public function removeAllSystems(group:Group = null, systemManager:Engine = null):void
		{						
			if(group == null)
			{
				group = defaultGroup;
			}
			
			if (systemManager == null)
			{
				systemManager = getSystemManager(group);
			}
			
			var systems:LinkedList = _systems[group];
			
			if(systems != null)
			{
				var iterator:ILinkedListIterator = systems.iterator() as ILinkedListIterator;
				
				while( iterator.hasNext() )
				{
					var system:System = System(iterator.next());
					
					if(!isSystemInUse(system, group))
					{
						removeSystem(system, group, systemManager);
					}
				}
				
				iterator = null;
			}
			
			delete _systems[group];
		}
		
		/**
		 * Remove all entities in a group
		 * @param   [group] : the group the system is part of, defaults to the current scene.
		 * @param   [systemManager] : The Engine instance to remove from.  Defaults to the primary _gameSystemManager instance.
		 */
		public function removeAllEntities(group:Group = null, systemManager:Engine = null):void
		{						
			if(group == null)
			{
				group = defaultGroup;
			}
			
			if (systemManager == null)
			{
				systemManager = getSystemManager(group);
			}
			
			var entities:LinkedList = _entities[group];
			if(entities)
			{
				var iterator:ILinkedListIterator = entities.iterator() as ILinkedListIterator;
				
				while( iterator.hasNext() )
				{
					removeEntity(Entity(iterator.next()), group, systemManager);				
				}
				
				iterator.remove();
				
				delete _entities[group];
			}
		}	
		
		/**
		 * Get access to an entity by its Id component
		 * @param	id : a string matching a component id you're looking for.
		 * @param   [group] : the group the entity is part of, defaults to the current scene.
		 * @param   [parent] : an optional param if you only want entities belonging to a particular parent.
		 */
		public function getEntityById(id:String, group:Group = null, parent:Entity = null):Entity
		{
			if(parent)
			{
				return(EntityUtils.getChildById(parent, id));
			}
			else
			{
				if(group == null)
				{
					group = getOwningGroup(parent);
				}
				
				var entities:LinkedList = _entities[group];
				
				if(entities == null)
				{
					return(null);
				}
				
				var iterator:ILinkedListIterator = entities.iterator() as ILinkedListIterator;
				var element:Object;
				var nextId:Id;
				
				while( iterator.hasNext() )
				{
					element = iterator.next();
					nextId = Entity(element).get(Id);
					
					if(nextId != null)
					{
						if(nextId.id == id)
						{
							return(Entity(element));
						}
					}
				}
			}
						
			return(null);
		}
		
		/**
		 * Get an array of all a parents children's components of a particular type.
		 * @param	id : a string matching a component id you're looking for.
		 * @param   [group] : the group the entity is part of, defaults to the current scene.
		 * @param   [parent] : an optional param if you only want entities belonging to a particular parent.
		 */
		public function getChildComponents(parent:Entity, componentClass:*):Array
		{
			var component:*;
			var components:Array = new Array();
			var children:Children = parent.get(Children);
			var child:Entity;
			
			if(children != null)
			{
				for(var n:uint = 0; n < children.children.length; n++)
				{
					child = children.children[n];
					component = child.get(componentClass);
					
					if(component != null)
					{
						components.push(component);
					}
				}
			}
			
			return(components);
		}
		
		/**
		 * Get a group with a matching id
		 * @param	id : a string matching a groups id
		 */
		public function getGroupById(id:String, parent:Group = null):Group
		{
			for each(var group:Group in _groups)
			{
				if(group.id == id)
				{
					if(parent == null || isParent(group, parent) && !group.removalPending)
					{
						return(group);
					}
				}
			}
			
			return(null);
		}
		
		/**
		 * Checks to see if group is present.
		 * Useful for race condition, for example if a handler is called after the group has been removed.
		 */
		public function hasGroup(group:Group):Boolean
		{
			for each(var listedGroup:Group in _groups)
			{
				if(listedGroup == group)
				{
					return true;
				}
			}
			
			return false;
		}
		
		/**
		 * Checks all the parents of a childs parent to look for a common parent.
		 */
		public function isParent(child:Group, parent:Group):Boolean
		{
			if(child.parent == parent)
			{
				return(true);
			}
			else if(child.parent != null)
			{
				return(isParent(child.parent, parent));
			}
			
			return(false);
		}

		//// PROTECTED METHODS ////

		protected override function destroy():void
		{
			removeAll();
			super.destroy();
		}

		//// PRIVATE METHODS ////

		/**
		 * Helper function, returns OwningGroup from entity if it exists, otherwise the default group.
		 * @param	entity : The entity with an OwningGroup component
		 */
		private function getOwningGroup(entity:Entity = null):Group
		{
			if (entity != null)
			{
				/*
				var owningGroup:OwningGroup = entity.get(OwningGroup);
				
				if (owningGroup)
				{
					if (owningGroup.group)
					{
						return(owningGroup.group);
					}
				}
				*/
				
				if(entity.group != null) { return(entity.group); }
			}
			
			return(defaultGroup);
		}
		
		/**
		 * Helper function, returns the systemManager (Engine instance) from entity if it exists, otherwise the default _gameSystemManager.
		 * @param	group : The group being checked for a systemManager
		 */
		private function getSystemManager(group:Group):Engine
		{
			if(group != null)
			{
				if(group.systemManager != null)
				{
					return(group.systemManager);
				}
			}
			
			return(_systemManager);
		}
		
		/**
		 * Checks a group and all of its children to see if a System is being used by any of them.
		 */
		private function isSystemInUse(system:System, ignore:Group):Boolean
		{
			var systems:LinkedList;
			var iterator:ILinkedListIterator;
			var nextSystem:System;
			
			for each(var nextGroup:Group in _groups)
			{
				if(nextGroup != ignore)
				{
					systems = _systems[nextGroup];
					iterator = systems.iterator() as ILinkedListIterator;
					
					while(iterator.hasNext())
					{
						nextSystem = System(iterator.next());
						
						if(nextSystem == system)
						{
							iterator = null;
							return(true);
						}
					}
				}
			}
			
			return(false);
		}
		
		private function removeReady(group:Group, systemManager:Engine):void
		{						
			if(group == defaultGroup)
			{
				this.defaultGroup = null;
			}
			
			if (systemManager == null)
			{
				systemManager = _systemManager;
			}
		
			removeAllSystems(group, systemManager);
			removeAllEntities(group, systemManager);
			removeAllElements(group);
			delete _groups[group];
			
			trace("GroupManager :: Group Removed : " + group);
		}
		
		public function get systemManager():Engine { return this._systemManager; }
						
		public var defaultGroup:Group;
		private var _systemManager:Engine;
		private var _systems:Dictionary = new Dictionary(true);
		private var _entities:Dictionary = new Dictionary(true);
		private var _groups:Dictionary = new Dictionary(true);
		private var _elements:Dictionary = new Dictionary(true);
	}
}
