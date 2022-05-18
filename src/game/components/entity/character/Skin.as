package game.components.entity.character
{	
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.entity.State;
	import game.components.entity.character.part.SkinPart;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.util.DataUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Holds reference to all Entities with SkinPart components for a single character.
	 */
	public class Skin extends Component
	{
		public function Skin()
		{
			_skinPartEntities = new Dictionary();
			lookLoadComplete = new Signal();
			partsLoading = new Vector.<String>();
		}
		
		private var _skinPartEntities:Dictionary;			// of Entities with SkinParts
		public var partsLoading:Vector.<String>;
		public var lookLoadComplete:Signal;					// dispatched when all of part assets have completed loading
		public var ignoreBitmap:Boolean = false;			// if true, cancels bitmapping of parts associated with skin
		public var allowSpecialAbilities:Boolean = true;	// whether special abilites will be added to skin parts
		
		/**
		 * 
		 * @param	skin
		 */
		/**
		 * Adds reference to SkinPart, allowing SkinParts to be accessed from Skin.
		 * @param	skinPartEntity
		 * @param	id - should be the same as the SkinPart id variable
		 */
		public function addSkinPartEntity( skinPartEntity:Entity, id:String ):void
		{
			if ( getSkinPartEntity(id) == null )
			{
				_skinPartEntities[id] = skinPartEntity;
			}
		}
		
		public function getSkinPartEntity( id:String ):Entity
		{
			var skinPartEntity:Entity = _skinPartEntities[ id ];
			if ( skinPartEntity != null )
			{
				return skinPartEntity;
			}
			else
			{
				//trace( "Error :: Skin :: getSkinPart :: Skin does not contain skinPartEntity with id : " + id );
				return null;
			}
		}
		
		/**
		 * Get SkinPart with corresponding id.
		 * @param	id
		 * @return
		 */
		public function getSkinPart( id:String ):SkinPart
		{
			var skinPartEntity:Entity = getSkinPartEntity( id );
			if ( skinPartEntity )
			{
				var skinPart:SkinPart = skinPartEntity.get( SkinPart ) as SkinPart;
				if ( skinPart != null )
				{
					return skinPart;
				}
				else
				{
					trace( "Skin :: getSkinPart :: Entity does not contain SkinPart." );
				}
			}
			return null;
		}
		
		/**
		 * Sets all current SkinPart values to be permanent.
		 * NOT IN USE CURRENTLY - bard
		 */
		public function confirmAll():void
		{
			for each ( var skinPartEntity:Entity in _skinPartEntities )
			{
				SkinPart(skinPartEntity.get( SkinPart )).confirmValue();
			}
		}
		
		
		/**
		 * Reverts all current SkinPart values to there permanent value.
		 */
		public function revertAll():void
		{
			for each ( var skinPartEntity:Entity in _skinPartEntities )
			{
				SkinPart(skinPartEntity.get( SkinPart )).revertValue();
			}
		}
		
		/**
		 * Applies LookData to SkinParts.  
		 * LookData values overwrite SkinPart values.
		 * @param	look
		 * @param	isPermanent
		 */
		public function applyLook( look:LookData, isPermanent:Boolean = true  ):void
		{	
			if( look )
			{
				var skinPart:SkinPart;
				for each ( var lookAspect:LookAspectData in look.lookAspects )
				{ 
					skinPart = getSkinPart( lookAspect.id )
					if ( skinPart )
					{
						if ( DataUtils.isValidStringOrNumber( lookAspect.value ) )
						{
							skinPart.setValue( lookAspect.value, isPermanent );
						}
					}
					else
					{
						//trace( "Error :: Skin :: applyLook :: LookAspectData id : " + lookAspect.id + " did not find a matching SkinPart within skin." ); 
					}
				}
			}
		}
		
		/**
		 * Applies LookData to SkinParts.  
		 * LookData values overwrite SkinPart values.
		 * @param	look
		 * @param	isPermanent
		 */
		public function revertRemoveLook( look:LookData, isPermanent:Boolean = true):void
		{
			var skinPart:SkinPart;
			for each ( var lookAspect:LookAspectData in look.lookAspects )
			{ 
				skinPart = getSkinPart( lookAspect.id )
				if ( skinPart )
				{
					if( !skinPart.isPermanent() )		// if current value is not the permanent value, revert
					{
						skinPart.revertValue();
					}
					else
					{
						skinPart.remove( isPermanent );
					}
				}
				else
				{
					trace( "Error :: Skin :: revertRemoveLook :: LookAspectData id : " + lookAspect.id + " did not find a matching SkinPart within skin." ); 
				}
			}
		}
		
		public function bitmapSourceVisible( showSource:Boolean = true ):void
		{
			var display:Display;
			for each ( var skinPartEntity:Entity in _skinPartEntities )
			{
				display = skinPartEntity.get(Display);
				if( display != null && display.bitmapWrapper != null )
				{
					display.bitmapWrapper.sourceVisible( showSource );
				}
			}
		}
		
		///////////////////////////////////////////////////////////////////
		////////////////////////// LOAD CHECKING //////////////////////////
		///////////////////////////////////////////////////////////////////
		
		
		/**
		 * Used to track when all of the parts from a particular look have been loaded.
		 * Called by dispatch from SkinSystem.
		 * If a part is hidden by another part, then this is called (so this may be called twice for a part)
		 * @param skinPart
		 */
		public function partLoaded( skinPart:SkinPart ):void
		{
			// check if the part is in the list, then remove if found
			var index:int = partsLoading.indexOf( skinPart.id );
			if (index != -1)
			{
				partsLoading.splice( partsLoading.indexOf( skinPart.id ), 1 );
			}
			if ( partsLoading.length == 0 )
			{
				// once parts have completed loading, check for meta complete
				partsMetaComplete();
			}
		}
		
		/**
		 * Used to track when all of the parts have completed updated driven by meta data.
		 * Is passed as handler within SkinCreator, called by dispatch from AnimationStateSystem &amp; ColorDisplaySystem
		 * @param skinPartEntity
		 * 
		 */
		public function partsMetaComplete( skinPartEntity:Entity = null ):void
		{
			if( lookLoadComplete.numListeners > 0 )
			{
				if( partsLoading.length == 0 )
				{
					// search through all parts, looking for any meta vakues that may be invalidated
					for each( skinPartEntity in _skinPartEntities )
					{
						// check color
						var colorSet:ColorSet = skinPartEntity.get( ColorSet );
						if( colorSet )
						{
							if( colorSet.invalidate )
							{
								return;
							}
						}
						
						// check state
						var state:State = skinPartEntity.get( State );
						if( state )
						{
							if( state.invalidate )
							{
								if( !state.hasChanged )
								{
									return;
								}
							}
						}
					}
					lookLoadComplete.dispatch();
				}
			}
		}
	}
}
