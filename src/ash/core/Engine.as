package ash.core
{
	import flash.utils.Dictionary;
	
	import ash.signals.Signal0;

	/**
	 * The Engine class is the central point for creating and managing your game state. Add
	 * entities and systems to the engine, and fetch families of nodes from the engine.
	 */
	public class Engine
	{
		private var entityNames : Dictionary;
		private var entityList : EntityList;
		private var systemList : SystemList;
		private var families : Dictionary;
		
		/**
		 * Indicates if the engine is currently in its update loop.
		 */
		public var updating : Boolean;
		
		/**
		 * Dispatched when the update loop ends. If you want to add and remove systems from the
		 * engine it is usually best not to do so during the update loop. To avoid this you can
		 * listen for this signal and make the change when the signal is dispatched.
		 */
		public var updateComplete : Signal0;
		
		/**
		 * The class used to manage node lists. In most cases the default class is sufficient
		 * but it is exposed here so advanced developers can choose to create and use a 
		 * different implementation.
		 * 
		 * The class must implement the Family interface.
		 */
		public var familyClass : Class = ComponentMatchingFamily;
		
		public function Engine()
		{
			entityList = new EntityList();
			entityNames = new Dictionary();
			systemList = new SystemList();
			families = new Dictionary();
			updateComplete = new Signal0();
			
			this.fixedTimestepAccumulatorRatio = new Dictionary();
			_fixedTimestepAccumulator = new Dictionary();
		}
		
		/**
		 * Add an entity to the engine.
		 * 
		 * @param entity The entity to add.
		 */
		public function addEntity( entity : Entity ) : void
		{
			if( entityNames[ entity.name ] )
			{
				throw new Error( "The entity name " + entity.name + " is already in use by another entity." );
			}
			entityList.add( entity );
			entityNames[ entity.name ] = entity;
			entity.componentAdded.add( componentAdded );
			entity.componentRemoved.add( componentRemoved );
			entity.nameChanged.add( entityNameChanged );
			for each( var family : IFamily in families )
			{
				family.newEntity( entity );
			}
		}
		
		/**
		 * Remove an entity from the engine.
		 * 
		 * @param entity The entity to remove.
		 */
		public function removeEntity( entity : Entity ) : void
		{
			entity.componentAdded.remove( componentAdded );
			entity.componentRemoved.remove( componentRemoved );
			entity.nameChanged.remove( entityNameChanged );
			for each( var family : IFamily in families )
			{
				family.removeEntity( entity );
			}
			delete entityNames[ entity.name ];
			entityList.remove( entity );
			
			entity.destroy();
		}
		
		private function entityNameChanged( entity : Entity, oldName : String ) : void
		{
			if( entityNames[ oldName ] == entity )
			{
				delete entityNames[ oldName ];
				entityNames[ entity.name ] = entity;
			}
		}
		
		/**
		 * Get an entity based n its name.
		 * 
		 * @param name The name of the entity
		 * @return The entity, or null if no entity with that name exists on the engine
		 */
		public function getEntityByName( name : String ) : Entity
		{
			return entityNames[ name ];
		}
		
		/**
		 * Remove all entities from the engine.
		 */
		public function removeAllEntities() : void
		{
			while( entityList.head )
			{
				removeEntity( entityList.head );
			}
			
			entityList.head = entityList.tail = null;
		}
		
		/**
		 * Returns a vector containing all the entities in the engine.
		 */
		public function get entities() : Vector.<Entity>
		{
			var entities : Vector.<Entity> = new Vector.<Entity>();
			for( var entity : Entity = entityList.head; entity; entity = entity.next )
			{
				entities.push( entity );
			}
			return entities;
		}
		
		/**
		 * @private
		 */
		private function componentAdded( entity : Entity, componentClass : Class ) : void
		{
			for each( var family : IFamily in families )
			{
				family.componentAddedToEntity( entity, componentClass );
			}
		}
		
		/**
		 * @private
		 */
		private function componentRemoved( entity : Entity, componentClass : Class ) : void
		{
			for each( var family : IFamily in families )
			{
				family.componentRemovedFromEntity( entity, componentClass );
			}
		}
		
		/**
		 * Get a collection of nodes from the engine, based on the type of the node required.
		 * 
		 * <p>The engine will create the appropriate NodeList if it doesn't already exist and 
		 * will keep its contents up to date as entities are added to and removed from the
		 * engine.</p>
		 * 
		 * <p>If a NodeList is no longer required, release it with the releaseNodeList method.</p>
		 * 
		 * @param nodeClass The type of node required.
		 * @return A linked list of all nodes of this type from all entities in the engine.
		 */
		public function getNodeList( nodeClass : Class ) : NodeList
		{
			if( families[nodeClass] )
			{
				return IFamily( families[nodeClass] ).nodeList;
			}
			var family : IFamily = new familyClass( nodeClass, this );
			families[nodeClass] = family;
			for( var entity : Entity = entityList.head; entity; entity = entity.next )
			{
				family.newEntity( entity );
			}
			return family.nodeList;
		}
		
		/**
		 * If a NodeList is no longer required, this method will stop the engine updating
		 * the list and will release all references to the list within the framework
		 * classes, enabling it to be garbage collected.
		 * 
		 * <p>It is not essential to release a list, but releasing it will free
		 * up memory and processor resources.</p>
		 * 
		 * @param nodeClass The type of the node class if the list to be released.
		 */
		public function releaseNodeList( nodeClass : Class ) : void
		{
			if( families[nodeClass] )
			{
				families[nodeClass].cleanUp();
			}
			delete families[nodeClass];
		}
		
		/**
		 * Add a system to the engine, and set its priority for the order in which the
		 * systems are updated by the engine update loop.
		 * 
		 * <p>The priority dictates the order in which the systems are updated by the engine update 
		 * loop. Lower numbers for priority are updated first. i.e. a priority of 1 is 
		 * updated before a priority of 2.</p>
		 * 
		 * @param system The system to add to the engine.
		 * @param priority The priority for updating the systems during the engine loop. A 
		 * lower number means the system is updated sooner.
		 */
		public function addSystem( system : System, priority : int ) : void
		{
			if(!isNaN(system.fixedTimestep))
			{
				if(system.linkedUpdate == null)
				{
					system.linkedUpdate = "fixed" + _fixedIdCounter++;
				}
			}
			
			system.priority = priority;
			system.addToEngine( this );
			systemList.add( system );
		}
		
		/**
		 * Get the system instance of a particular type from within the engine.
		 * 
		 * @param type The type of system
		 * @return The instance of the system type that is in the engine, or
		 * null if no systems of this type are in the engine.
		 */
		public function getSystem( type : Class ) : System
		{
			return systemList.get( type );
		}
		
		/**
		 * Returns a vector containing all the systems in the engine.
		 */
		public function get systems() : Vector.<System>
		{
			var systems : Vector.<System> = new Vector.<System>();
			for( var system : System = systemList.head; system; system = system.next )
			{
				systems.push( system );
			}
			return systems;
		}
		
		/**
		 * Remove a system from the engine.
		 * 
		 * @param system The system to remove from the engine.
		 */
		public function removeSystem( system : System ) : void
		{
			systemList.remove( system );
			system.removeFromEngine( this );
			system.group = null;
		}
		
		/**
		 * Remove all systems from the engine.
		 */
		public function removeAllSystems() : void
		{
			while( systemList.head )
			{
				removeSystem( systemList.head );
			}
			
			systemList.head = systemList.tail = null;
		}

		/**
		 * Update the engine. This causes the engine update loop to run, calling update on all the
		 * systems in the engine.
		 * 
		 * <p>The package net.richardlord.ash.tick contains classes that can be used to provide
		 * a steady or variable tick that calls this update method.</p>
		 * 
		 * @time The duration, in seconds, of this update step.
		 */
		public function update( time : Number) : void
		{
			updating = true;

			for( var system : System = systemList.head; system; system = system.next )
			{
				/**
				 * use fixed time updates to decouple rendering from motion as well as allowing systems to set a consistent update interval (ex : timeline animation).                                                            
				 * sources :                                                                                                                      
				 *   @see http://gafferongames.com/game-physics/fix-your-timestep/                                                                     
				 *   @see http://blog.allanbishop.com/box-2d-2-1a-tutorial-part-10-fixed-time-step/ 
				 * 
				 * If a system has a 'fixedTimestep' property it will be executed no more often than the timestep allows if 'time'
				 * is less than the timestep.  If it is greater it will execute multiple times to 'catch up'.
				 * 
				 * If a system also has a 'linkedUpdate' property it will be updated with all other systems which share that property.
				 * This is necessary for motion updates that need to have collision updates happen in sync.
				 */ 
				if( this.fixedTimestepUpdates && !isNaN( system.fixedTimestep ) )
				{
					if( _linkedSystems.indexOf( system.linkedUpdate ) == -1 )
					{
						_linkedSystems.push( system.linkedUpdate );
						updateFixedTimeSystems( time, system.fixedTimestep, system.linkedUpdate );	
					}
				}
				else
				{
					system.update( time );
				}
			}
			
			_linkedSystems.length = 0;
			updating = false;
			updateComplete.dispatch();
		}
	
		private function updateFixedTimeSystems( time : Number, step : Number, linkID:String ) : void
		{
			if(_fixedTimestepAccumulator[linkID] == null)
			{
				_fixedTimestepAccumulator[linkID] = 0;
				this.fixedTimestepAccumulatorRatio[linkID] = 0;
			}
			
			_fixedTimestepAccumulator[linkID] += time;     
			// interpolate between the previous and current physics state based on how much time is left in the accumulator   
			const nSteps:int = Math.floor(_fixedTimestepAccumulator[linkID] / step);                                                
			
			if (nSteps > 0)                                                                                                           
			{                                                                                                                         
				_fixedTimestepAccumulator[linkID] -= nSteps * step;                                                                 
			}                                                                                                                         
			
			this.fixedTimestepAccumulatorRatio[linkID] = _fixedTimestepAccumulator[linkID] / step;                                              
			
			const nStepsClamped:int = Math.min(nSteps, MAX_STEPS); 

			// run as many physics updates as needed to fill the amount of time that has passed since last update.                    
			for ( var i : int = 0; i < nStepsClamped; ++i )                                                                               
			{                                                                                                                         
				for( var system : System = systemList.head; system; system = system.next )
				{
					if(system.linkedUpdate == linkID)
					{
						if(nStepsClamped > 1)
						{
							if(system.onlyApplyLastUpdateOnCatchup && i != nStepsClamped - 1)
							{
								continue;
							}
						}
						system.update( step );
					}
				}
			}                                                                                                                         
		}
		
		/*************************************************
		 * Check for the presence of a node family. - Need this for DynamicSystems
		 */
		public function hasNodeList( nodeClass : Class ) : Boolean
		{
			if (families[nodeClass])
			{
				return(true);
			}
			else
			{
				return(false);
			}
		}

		/**************************************************/
		/*************************************************
		 * Fixed timestep properties.
		 */		
		public var fixedTimestepAccumulatorRatio:Dictionary;
		public var fixedTimestepUpdates:Boolean = true;
		private var _fixedTimestepAccumulator:Dictionary;        
		private var _linkedSystems:Vector.<String> = new Vector.<String>;
		private var _fixedIdCounter:int = 0;
		// max physics steps to avoid 'spiral of death' (physics updates never catch up). 
		private const MAX_STEPS:int = 5;
		/**************************************************/
	}
}
