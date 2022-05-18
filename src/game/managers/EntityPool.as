package game.managers
{
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.util.EntityUtils;

	public class EntityPool
	{

		public static const DEFAULT_TYPE:String = "any";

		public function EntityPool()
		{
			_pool = new Dictionary();
			_poolSize = new Dictionary();
		}
		
		public function destroy():void
		{
			_pool = new Dictionary();
			_poolSize = new Dictionary();
		}
		
		/**
		 * Releases an Entity back into the pool, or adding Entitis into the pool if was not there originally.
		 * If type is defined will release Entity into specified pool, otherwise will use the default type.
		 * Pool type will be created if it does not yet exist.
		 * @param entity - entity being return/added to pool
		 * @param type - type of entity, string used as key to access associated Dictionaries
		 * @return - returns tue if Entity was successfully/returns/added to pool.
		 */
		public function release(entity:Entity, type:String = DEFAULT_TYPE):Boolean
		{
			if(_pool[type] == null)
			{
				_pool[type] = new Vector.<Entity>;
				
				if(_poolSize[type] == null)
				{
					_poolSize[type] = DEFAULT_MAX_POOL_SIZE;
				}
			}
			// only add an entity to the pool if it isn't already there.
			if(Vector.<Entity>(_pool[type]).indexOf(entity) == -1)
			{
				if(_pool[type].length >= _poolSize[type])
				{
					var oldestEntity:Entity = _pool[type].shift();
					if(EntityUtils.sleeping(oldestEntity))
					{
						entity.group.removeEntity(entity);
					}
				}
				
				_pool[type].push(entity);
				
				return(true);
			}
			
			return(false);
		}
		
		/**
		 * Move an Entity from one pool type to another.
		 * If no entity is given, will transfer next available entity.
		 * @param fromType
		 * @param toType
		 * @param entity
		 * @return 
		 */
		public function transfer(fromType:String, toType:String, entity:Entity = null):Entity
		{
			if( entity == null )
			{
				entity = this.request( fromType );
			}
			else
			{
				entity = this.requestSpecific(entity, fromType);
			}
			
			if( entity )
			{
				release(entity, toType);
			}
			return(entity);
		}
		
		/**
		 * Retrieve an Entity from the pool 
		 * @param type
		 * @return 
		 * 
		 */
		public function request(type:String = DEFAULT_TYPE):Entity
		{
			if(_pool[type] != null)
			{
				if(_pool[type].length > 0)
				{
					return(_pool[type].pop());
				}
			}
			return(null);
		}
		
		/**
		 * Remove an entity from pool 
		 * @param entity
		 * @param type
		 * @return 
		 * 
		 */
		private function requestSpecific(entity:Entity, type:String = DEFAULT_TYPE):Entity
		{
			if(_pool[type] != null)
			{
				if(_pool[type].length > 0)
				{
					var index:int = Vector.<Entity>(_pool[type]).indexOf(entity);
					if(index != -1)
					{
						Vector.<Entity>(_pool[type]).splice(index, 1);
						return entity;
					}
				}
			}
			return(null);
		}
		
		/**
		 * Empties pool of all Entities, regardless of type, within specified group. 
		 * @param group
		 */
		public function empty(group:Group):void
		{
			for each(var entityPool:Vector.<Entity> in _pool)
			{
				for(var n:uint = 0; n < entityPool.length; n++)
				{
					group.removeEntity(entityPool[n], true);
				}
				
				entityPool = null;
			}
			
			_pool = new Dictionary();
		}
		
		/**
		 * Set max size of pool. 
		 * @param type
		 * @param size
		 */
		public function setSize(type:String = DEFAULT_TYPE, size:int = DEFAULT_MAX_POOL_SIZE):void
		{
			_poolSize[type] = size;
		}
		
		public function getPool(type:String):Vector.<Entity>
		{
			return _pool[type];
		}
		
		private var _pool:Dictionary;
		private var _poolSize:Dictionary;
		private const DEFAULT_MAX_POOL_SIZE:int = 50;
	}
}