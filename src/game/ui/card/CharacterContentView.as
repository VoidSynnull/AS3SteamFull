package game.ui.card
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.Skin;
	import game.components.motion.Edge;
	import game.components.ui.CardItem;
	import game.creators.entity.character.CharacterCreator;
	import game.data.ParamData;
	import game.data.TimedEvent;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.text.TextData;
	import game.data.ui.card.CardItemData;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ui.CardGroup;
	import game.systems.entity.EyeSystem;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;

	public class CharacterContentView extends CardContentView
	{
		/**
		 * Interface class for the card content
		 */
		public function CharacterContentView(container:DisplayObjectContainer = null) 
		{
			super(container);
			// NOTE :: refreshing the look is still kind of buggy, likely loading racing conditions.  Turning this off for now.
			super.canRefresh = false;	
		}

		override public function destroy():void
		{
			_charEntity = null;
			_loadingWheel = null;
			_charContainer = null;
			super.destroy();
		}
		
		override public function create( cardItem:CardItem, handler:Function = null ):void
		{
			_cardItem = cardItem;
			_id = cardItem.cardData.id;
			
			// check for store instructions
			for each (var td:TextData in cardItem.cardData.textData)
			{
				if (td.id == "storeInstructions")
				{
					_hasInstructions = true;
				}
				else if (td.id == "storeTitle")
				{
					_hasStoreTitle = true;
					_isStoreCard = true;
				}
				else if (td.id == "storeTitle2")
				{
					_hasStoreTitle2 = true;
					_isStoreCard = true;
				}
			}
			
			if( super.loadingWrapper )
			{
				_loadingWheel = EntityUtils.createMovingEntity( this, super.loadingWrapper.sprite, super.groupContainer );
				_loadingWheel.add( new Sleep() );	// if we want to save this we could use sleep
				Motion(_loadingWheel.get(Motion)).rotationVelocity = LOADER_SPIN_SPEED;
			}
			
			if(_cardItem.cardData.cardClassParams)
			{
				var data:ParamData = _cardItem.cardData.cardClassParams.getParamId("clickableSpecial");
				if(data)
				{
					_clickableSpecial = DataUtils.getBoolean(data.value);
				}
			}
			
			var charGroup:CharacterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			
			charGroup = super.getGroupById("characterGroup" ) as CharacterGroup;
			if( charGroup == null )
			{
				charGroup = super.addChildGroup( new CharacterGroup() ) as CharacterGroup;
			}
			
			_charContainer = new Sprite();
			super.groupContainer.addChild( _charContainer );
			_charContainer.visible = false;	
	
			// get look (player or pet)
			var look:LookData = getLook(_cardItem);
			
			// set variant
			var variant:String = "";
			if (_isPet)
			{
				variant = CharacterCreator.VARIANT_PET_BABYQUAD;
			}
			if(!shellApi.sceneManager.currentScene.sceneData.hasPlayer)
			{
				charGroup.setupGroup(this, _charContainer);
			}
			_charEntity = charGroup.createDummy( "cardDummy", look, CharUtils.DIRECTION_LEFT, variant, _charContainer, this, Command.create( onCharLoaded, handler ), false, NaN);
		}
		
		/**
		 * Start the character animation 
		 */
		override public function start():void
		{
			CharUtils.freeze( _charEntity, false );
		}
		
		/**
		 * Stop the character animation 
		 */
		override public function stop():void
		{
			CharUtils.freeze( _charEntity, true );
		}
		
		override public function update( cardItem:CardItem ):void
		{
			var lookData:LookData = cardItem.cardData.getLook(cardItem.value);
			if( lookData )
			{
				if( _charEntity )
				{
					SkinUtils.applyLook( _charEntity, lookData );
				}
			}
			
			if(cardItem.cardData.specialIds && cardItem.value != "0" && !_isPet)
			{
				var data:SpecialAbilityData = shellApi.specialAbilityManager.addSpecialAbilityById(_charEntity, cardItem.value, true);
				
				if(_clickableSpecial)
				{
					data.fullyLoaded.addOnce(abilityDataLoaded);
				}
			}	
		}
		
		private function abilityDataLoaded(data:SpecialAbilityData):void
		{
			if(data.entity)
			{
				data.specialAbility.makeContentClickable();
				data.specialAbility.specialClicked.addOnce(nextSpecial);
			}
		}
		
		private function nextSpecial(data:SpecialAbilityData):void
		{
			_clickableIndex = _clickableIndex + 1 < _cardItem.cardData.specialIds.length ? _clickableIndex + 1 : 0;
			
			var cardGroup:CardGroup = getGroupById(CardGroup.GROUP_ID) as CardGroup;
			cardGroup.updateValue(_cardItem, _cardItem.cardData.specialIds[_clickableIndex]); 	
		}
		
		// when look is loaded
		private function onCharLoaded( character:Entity, handler:Function = null ):void
		{
			// NOTE :: possible that CharacterContentView has already been removed, check before proceeding
			if( super.groupManager.hasGroup( this ) )
			{
				super.unpause();
				
				// removing sleep fixes the problem with strange results with avatar heights
				_charEntity.remove(Sleep);
				
				var cardData:CardItemData = _cardItem.cardData;
				
				CharUtils.setDirection( _charEntity, true );
				Character(character.get(Character)).costumizable = false;
				// set to default card scale
				CharUtils.setScale( _charEntity, CHAR_SIZE );
				CharUtils.freeze( _charEntity, true );
				
				// if not store card
				if (!_isStoreCard)
				{
					Spatial( _charEntity.get(Spatial)).y = Y_OFFSET;
				}
				
				Display(_charEntity.get(Display)).visible = true;
	
				// wait for a few updates before displaying
				var timedEvent:TimedEvent = new TimedEvent(CHAR_LOAD_DELAY, 1, Command.create( onCharComplete, handler ));
				timedEvent.countByUpdate = true;
				SceneUtil.addTimedEvent( this, timedEvent );
				
				if((cardData.specialIds) && (!_isPet))
				{
					if(!_clickableSpecial)
					{
						for each(var id:String in cardData.specialIds)
						{
							shellApi.specialAbilityManager.addSpecialAbilityById(_charEntity, id, true);
						}
					}
					else
					{
						_clickableAbility = true;
						var specialData:SpecialAbilityData = shellApi.specialAbilityManager.addSpecialAbilityById(_charEntity, cardData.specialIds[_clickableIndex], true);
						specialData.fullyLoaded.addOnce(abilityDataLoaded);
					}
				}
			}
		}
		
		private function onCharComplete( handler:Function = null ):void
		{	
			if( _loadingWheel )
			{
				//super.removeEntity( _loadingWheel );	// NOTE :: Don't remove entity, can cause race condition error
				Sleep( _loadingWheel.get( Sleep ) ).sleeping = true;
				_loadingWheel.remove( Motion );
				_loadingWheel.remove( Display );
				_loadingWheel.remove( Spatial );
			}
			
			// use height of actual character, not container (container will include effects and be larger)
			var displayObj:DisplayObject = Display(_charEntity.get(Display)).displayObject;
			var height:Number = displayObj.height;
			
			// check for items that fall below feet
			var extendBelow:Number = displayObj.getBounds(displayObj).bottom - 109.55;
			if (extendBelow > 0)
			{
				height -= (extendBelow * CHAR_SIZE); 
			}
			//trace("rick height " + _id + " " + height);
			
			// check for avatar scale getting passed from xml
			var scale:Number = 0;
			var cardScale:Number = 0;
			var forceScale:Boolean = false;
			if(_cardItem.cardData.cardClassParams)
			{
				var data:ParamData = _cardItem.cardData.cardClassParams.getParamId("scale");
				if(data)
				{
					cardScale = DataUtils.getNumber(data.value) / CHAR_SIZE;
				}
				data = _cardItem.cardData.cardClassParams.getParamId("forceScale");
				if(data)
				{
					forceScale = DataUtils.getBoolean(data.value);
				}
				data = _cardItem.cardData.cardClassParams.getParamId("hidePlayer");
				if(data)
				{
					if(DataUtils.getBoolean(data.value) == true)
						_charEntity.get(Display).visible = false;
				}
			}
			
			// get bottom distance from centerpoint
			var bottom:Number = _charEntity.get(Edge).rectangle.bottom / _charEntity.get(Spatial).scale;
			
			if (_isPet)
			{
				scale = 8.75;
			}
			// if instructions below avatar
			else if (_hasInstructions)
			{
				scale = getDestScale(545, height, bottom);
			}
			// if two buttons
			else if (_hasStoreTitle2)
			{
				scale = getDestScale(510, height, bottom);
			}
			else if (_hasStoreTitle)
			{
				scale = getDestScale(640, height, bottom);
			}
			
			//trace("card id " + _id);
			// if card scale and calculated scale is less than card scale
			if ((forceScale) || ((cardScale != 0) && (scale > cardScale)))
			{
				scale = cardScale;
			}
			
			if (scale != 0)
			{
				if (_isStoreCard)
				{
					CharUtils.freeze( _charEntity, false );
					var yOffset:Number;
					// scale container. not character
					if (_isPet)
					{
						yOffset = 95;
						_charContainer.x = -15;
					}
					else if (_hasInstructions)
					{
						yOffset = 87;
					}
					else if (_hasStoreTitle)
					{
						yOffset = 126;
					}
					else if (_hasStoreTitle2)
					{
						yOffset = 74;
					}
					// get the avatar feet to align at 0
					_charEntity.get(Spatial).y = -_charEntity.get(Edge).rectangle.bottom;
					_charContainer.scaleX = _charContainer.scaleY = scale;
					_charContainer.y = yOffset;
					
				}
				else
				{
					CharUtils.setScale(_charEntity, scale);
				}
			}

			_charContainer.visible = true;
			
			// disable mouse clicks on character if item part drops below and not clickable ability
			if ((extendBelow > 10) && (!_clickableAbility))
			{
				_charContainer.parent.parent.mouseEnabled = false;
				_charContainer.parent.parent.mouseChildren = false;
			}
			
			if( handler != null )
			{
				handler();
			}
		}

		private function getDestScale(base:Number, height:Number, bottom:Number):Number
		{
			return base / height * CHAR_SIZE;
		}
		
		protected function getLook( cardItem:CardItem ):LookData
		{
			if(cardItem.cardData.cardClassParams)
			{
				var paramData:ParamData = cardItem.cardData.cardClassParams.getParamId("pet");
				if(paramData)
				{
					_isPet = DataUtils.getBoolean(paramData.value);
				}
			}

			var playerLook:LookData;
			
			if (_isPet)
			{
				// get pet look
				var data:SpecialAbilityData = shellApi.specialAbilityManager.getAbility("pets/pop_follower");
				if (data == null)
				{
					// set default pet look when no active pet
					playerLook = new LookData();
					playerLook.applyAspect( new LookAspectData( SkinUtils.GENDER, SkinUtils.GENDER_MALE ) );
					playerLook.applyAspect( new LookAspectData( SkinUtils.EYES, "eyes" ) );
					playerLook.applyAspect( new LookAspectData( SkinUtils.EYE_STATE, EyeSystem.OPEN ) );
					playerLook.applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, 0xFF7700 ) );
					playerLook.applyAspect( new LookAspectData( SkinUtils.MOUTH, "kitten" ) );
					playerLook.applyAspect( new LookAspectData( SkinUtils.MARKS, "kitten_ears" ) );
				}
				else
				{
					playerLook = data.specialAbility.getLook();
				}
			}
			else
			{
				// if player
				playerLook = SkinUtils.getPlayerLook( this, true );
					
				if(cardItem.cardData.cardClassParams != null)
				{
					if(DataUtils.getBoolean(cardItem.cardData.cardClassParams.byId("gender")))
					{
						cardItem.value = playerLook.getValue( SkinUtils.GENDER );
					}
				}
			}

			var npcLook:LookData;
			var cardlook:LookData = cardItem.cardData.getLook( cardItem.value );
			if( cardlook )
			{
				npcLook = new LookData();
				npcLook.fill( cardlook );
				npcLook.applyBaseLook(playerLook, _isPet);
				npcLook.fillWithEmpty();
				
				// set eye state
				var eyeState:String = EyeSystem.OPEN_STILL;				
				npcLook.applyAspect( new LookAspectData( SkinUtils.EYE_STATE, eyeState ) );	// TODO :: would like to just apply "_still" suffix if a state has already been set. -bard
			}
			else
			{
				npcLook = playerLook;
			}
			// if pet then apply saved pet color
			if (_isPet)
			{
				// get diff pet look and color
				var petLook:Object = shellApi.profileManager.active.pets["pet" + cardItem.itemId.substr(4)];
				if ((petLook != null) && (petLook[SkinUtils.SKIN_COLOR] != null))
				{
					var color:uint = petLook[SkinUtils.SKIN_COLOR];
					npcLook.applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, color ) );
				}
			}
			return npcLook;
		}
		
		override public function bitmapSourceVisible( showSource:Boolean = true ):void
		{
			// show source of skin part displays when preparing for bitmap
			var skin:Skin = _charEntity.get( Skin );
			skin.bitmapSourceVisible();
			super.bitmapSourceVisible( showSource );
		}

		private const LOADER_SPIN_SPEED:Number = 200;
		private const Y_OFFSET:Number = 20;
		private const CHAR_SIZE:Number = 0.4;
		private const CHAR_LOAD_DELAY:uint = 10;
		private var _charEntity:Entity;
		private var _loadingWheel:Entity;
		private var _charContainer:Sprite;
		private var _id:String;
		
		private var _cardItem:CardItem;
		private var _clickableIndex:uint = 0;
		private var _clickableSpecial:Boolean = false;
		private var _clickableAbility:Boolean = false;
		
		private var _isStoreCard:Boolean = false;
		private var _isPet:Boolean = false;
		private var _hasInstructions:Boolean = false;
		private var _hasStoreTitle:Boolean = false;
		private var _hasStoreTitle2:Boolean = false;
	}
}