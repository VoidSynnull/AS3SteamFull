package game.components.specialAbility
{
	import flash.ui.Keyboard;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Interaction;
	
	import game.data.specialAbility.SpecialAbilityData;
	import game.managers.WallClock;

	//import game.managers.AdManager;	
	
	public class SpecialAbilityControl extends Component
	{
		public function SpecialAbilityControl()
		{
			_specials = new Vector.<SpecialAbilityData>();
		}
		
		public var _invalidate:Boolean;							// set to true by trigger or when SpecialAbilityData is invalidated
		private var _spaceBarTimer:WallClock;					// timer for tracking calls to keep spaced apart
		private var _numPresses:int = 0;						// number of space bar presses accumulated
		
		/**
		 * Flag determining if SpecialAbilityControl can be activated by user input.
		 * For instance only the player should really be able to trigger their special abilities via input
		 * Other Entities that have speacila abilities should require the trigger to be called directly
		 */
		public var userActivated:Boolean = false;
		
		private var _specials:Vector.<SpecialAbilityData>;			
		public function get specials():Vector.<SpecialAbilityData>	{ return _specials; }
		public function set specials(vector:Vector.<SpecialAbilityData>):void	{ _specials = vector; }
		
		////////////////////////////////////////////////////////////////////////
		//////////////////////////////// TRIGGER ///////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		private var _trigger:Boolean;
		public function get trigger():Boolean	{ return _trigger; }
		public function set trigger(bool:Boolean):void
		{
			_trigger = bool;
			if ( _trigger )
			{
				_invalidate = true;
			}
		}
		
		///////////////////////////////// ACTION TRIGGERING ///////////////////////////////// 
		// TOUCH/MOBILE ONLY //
		
		private var _actionBtnUsers:Vector.<String>;
		
		/** Returns true if there are special abilities that use the action button */
		public function get hasActionBtnUsers():Boolean
		{
			return ( _actionBtnUsers != null && _actionBtnUsers.length > 0 );
		}
		
		/** Add special ability type to list of special abilities that use action button */
		public function addActionBtnUser( specialType:String ):void
		{
			if( _actionBtnUsers == null )
			{
				_actionBtnUsers = new Vector.<String>();
			}
			_actionBtnUsers.push( specialType );	// TODO :: Do we need to check for overlap, or is that already handled? - bard
		}
		
		/** Remove special ability type from list of special abilities that use action button */
		public function removeActionBtnUser( specialType:String ):void
		{
			if( _actionBtnUsers != null )
			{
				for (var i:int = 0; i < _actionBtnUsers.length; i++) 
				{
					if( _actionBtnUsers[i] == specialType )
					{
						_actionBtnUsers.splice(i,1);
					}
				}
			}
		}
		
		public function onTrigger(...args):void	
		{
			this.trigger = true; 
		}
		
		/**
		 * On browser special abilities are triggered by pressing spacebar 
		 * @param entity
		 */
		public function onKeyDownHandler( entity:Entity ):void
		{
			if(Interaction(entity.get(Interaction)).keyIsDown == Keyboard.SPACE)
			{
				Interaction(entity.get(Interaction)).keyUp.add(onKeyUpHandler);
			}
		}
		
		private function onKeyUpHandler(entity:Entity):void
		{
			if ( Interaction(entity.get(Interaction)).keyIsUp == Keyboard.SPACE )
			{
				onTrigger();
				//trackSpaceBar(entity);
			}
		}

		////////////////////////////////////////////////////////////////////////
		////////////////////////////// ADD ABILITY /////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		/**
		 * Add SpecialAbilityData, will overwrite any existing SpecialAbilityData with same type;
		 * @param	specialAbilityData
		 * @return
		 */
		public function addSpecial( specialAbilityData:SpecialAbilityData ):SpecialAbilityData
		{	
			// check for same type, but not same instance
			var existingSpecial:SpecialAbilityData = getSpecialByType( specialAbilityData.type );
			if ( existingSpecial == specialAbilityData )
			{
				return existingSpecial;
			}
			else if ( existingSpecial )
			{
				//existingSpecial.remove();
			}
			
			specialAbilityData.control = this;
			_specials.push( specialAbilityData );
			
			return specialAbilityData;
		}
		
		public function checkExistingType(specialAbilityData:SpecialAbilityData ):SpecialAbilityData
		{
			var existingSpecial:SpecialAbilityData = getSpecialByType( specialAbilityData.type );
			if ( existingSpecial != specialAbilityData )
			{
				return existingSpecial;
			}
			
			return null;
		}
		
		////////////////////////////////////////////////////////////////////////
		////////////////////////////// GET ABILITY /////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		/**
		 * Get SpecialAbilityData by type.
		 * @param	type - type of SpecialAbilityData, if not specifically set defaults to name of SpecialAbilityData Class
		 * @return
		 */
		public function getSpecialByType( type:String ):SpecialAbilityData
		{
			var specialData:SpecialAbilityData;
			for ( var i:uint = 0; i < _specials.length; i++ )
			{
				specialData = _specials[i];
				if( specialData.type == type )
				{
					return specialData;
				}
			}
			return null;
		}
		
		/**
		 * Get SpecialAbilityData by type.
		 * @param	type
		 * @return
		 */
		public function getSpecialByClass( specialClass:Class ):SpecialAbilityData
		{
			var specialData:SpecialAbilityData;
			for ( var i:uint = 0; i < _specials.length; i++ )
			{
				specialData = _specials[i];
				if( specialData.specialClass == specialClass )
				{
					return specialData;
				}
			}
			return null;
		}
		
		public function getSpecialById(id:String):SpecialAbilityData
		{
			var specialData:SpecialAbilityData;
			for(var i:uint = 0; i < _specials.length; i++)
			{
				specialData = _specials[i];
				if(specialData.id == id)
				{
					return specialData;
				}
			}
			return null;
		}
		
		/**
		 * Get SpecialAbilityData at provided index.
		 * @param	priority
		 * @return
		 */
		public function getSpecialAt( index:int ):SpecialAbilityData
		{
			if ( index > -1 && index < _specials.length )
			{
				return _specials[index];	
			}
			else
			{
				trace( " Error :: SpecialAbilityControl :: getSpecialAbilityAt :: No entity at index " + index );
				return null;
			}
		}
		
		/**
		 * Get last SpecialAbilityData added.
		 * @param	priority
		 * @return
		 */
		public function getSpecialLast():SpecialAbilityData
		{
			if ( _specials.length > 0 )
			{
				return _specials[_specials.length - 1];
			}
			return null;
		}
		
		////////////////////////////////////////////////////////////////////////
		//////////////////////////// REMOVE ABILITY ////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		public function removeSpecialById(id:String):void
		{
			var specialData:SpecialAbilityData = getSpecialById(id);
			if(specialData)
			{
				specialData.remove();
			}
		}
		
		/**
		 * Remove SpecialAbilityData by type.
		 * @param	type
		 */
		public function removeSpecialByType( type:String ):void
		{
			var specialData:SpecialAbilityData = getSpecialByType( type );
			if ( specialData )
			{
				specialData.remove();
			}
		}
		
		public function removeSpecialAbility(compare:SpecialAbilityData):void
		{
			var specialData:SpecialAbilityData;
			for(var i:uint = 0; i < _specials.length; i++)
			{
				specialData = _specials[i];
				if(specialData == compare)
				{
					trace("match");
					compare.remove();
				}
			}
		}
		
		/**
		 * Remove SpecialAbilityData by type.
		 * @param	type
		 */
		public function removeSpecialByClass( specialClass:Class ):void
		{
			var specialData:SpecialAbilityData = getSpecialByClass( specialClass );
			if ( specialData )
			{
				specialData.remove();
			}
		}
		
		/**
		 * Remove last SpecialAbilityData added.
		 * @param	type
		 */
		public function removeSpecialLast():void
		{
			if ( _specials.length > 0 )
			{
				_specials[_specials.length - 1].remove();
			}
		}
		
		/**
		 * Remove all SpecialAbilityDatas.
		 * @param	type
		 */
		public function removeSpecialAll():void
		{
			for ( var i:uint = 0; i < _specials.length; i++ )
			{
				_specials[i].remove();
			}
		}
	}
}