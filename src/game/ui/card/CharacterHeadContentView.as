package game.ui.card
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.ui.CardItem;
	import game.creators.entity.character.CharacterCreator;
	import game.data.ParamData;
	import game.data.TimedEvent;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.ui.card.CardItemData;
	import game.scene.template.CharacterGroup;
	import game.systems.entity.EyeSystem;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class CharacterHeadContentView extends CardContentView
	{
		public function CharacterHeadContentView(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function create(cardItem:CardItem, onComplete:Function=null):void
		{
			if(cardItem.cardData.cardClassParams){
				var data:ParamData = cardItem.cardData.cardClassParams.getParamId("fitHead");
				if(data){
					_fitHead = DataUtils.getBoolean(data.value);
				}
			}
			
			if( super.loadingWrapper )
			{
				_loadingWheel = EntityUtils.createMovingEntity( this, super.loadingWrapper.sprite, super.groupContainer );
				_loadingWheel.add( new Sleep() );	// if we want to save this we could use sleep
				Motion(_loadingWheel.get(Motion)).rotationVelocity = LOADER_SPIN_SPEED;
			}
			
			var charGroup:CharacterGroup = getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			if(charGroup == null)
			{
				charGroup = addChildGroup(new CharacterGroup()) as CharacterGroup;
			}
			
			_charContainer = new Sprite();
			groupContainer.addChild(_charContainer);
			_charContainer.visible = false;
			
			var lookData:LookData = getLook(cardItem);
			// fix for bobblehead card to force eyes open
			if (cardItem.itemId == "item3071")
			{
				lookData.setValue(SkinUtils.EYE_STATE, "open_still");
			}
			else
			{
				lookData.setValue(SkinUtils.EYE_STATE, "closed");
			}
			charGroup.createDummy("painted_dummy_head", lookData, "right", CharacterCreator.VARIANT_HEAD, _charContainer, this, Command.create(onCharLoaded, cardItem.cardData, onComplete), false, CHAR_SIZE);
		}
		
		private function onCharLoaded(character:Entity, cardData:CardItemData, handler:Function = null):void
		{
			if(groupManager.hasGroup(this))
			{
				this.unpause();
				Character(character.get(Character)).costumizable = false;
				
				character.get(Spatial).y = Y_OFFSET;
				character.get(Display).visible = true;
				if(_fitHead){
					var clip:DisplayObject = character.get(Display).displayObject;
					var difX:Number;
					var difY:Number;
					var difXPercent:Number = 0;
					var difYPercent:Number = 0;
					if(clip.width > _widthConstraint || clip.height > _heightConstraint){
						difX = clip.width - _widthConstraint;
						difY = clip.height - _heightConstraint;
						// convert diff to percent of current size
						if(difX>0){
							difXPercent = difX / clip.width;
						}
						if(difY>0){
							difYPercent = difY / clip.height;
						}
						// combine x/y diff to get new scale
						var avg:Number = (difXPercent + difYPercent)/2;
						Spatial(character.get(Spatial)).scale -=  avg;
						character.get(Spatial).y = Y_OFFSET + (Y_OFFSET * avg);
					}
				}
				
				var timedEvent:TimedEvent = new TimedEvent(CHAR_LOAD_DELAY, 1, Command.create( onCharComplete, handler ));
				timedEvent.countByUpdate = true;
				SceneUtil.addTimedEvent( this, timedEvent );
			}
		}
		
		private function onCharComplete(handler:Function = null):void
		{
			if(_loadingWheel)
			{
				Sleep( _loadingWheel.get( Sleep ) ).sleeping = true;
				_loadingWheel.remove( Motion );
				_loadingWheel.remove( Display );
				_loadingWheel.remove( Spatial );
			}
			
			_charContainer.visible = true;
			
			if( handler != null )
			{
				handler();
			}
		}
		
		protected function getLook( cardItem:CardItem ):LookData
		{
			var playerLook:LookData;
			playerLook = SkinUtils.getPlayerLook( this, true ).duplicate();
			
			if(cardItem.cardData.cardClassParams != null)
			{
				if(DataUtils.getBoolean(cardItem.cardData.cardClassParams.byId("gender")))
				{
					cardItem.value = playerLook.getValue( SkinUtils.GENDER );
				}
			}
			
			var npcLook:LookData;
			var cardlook:LookData = cardItem.cardData.getLook( cardItem.value );
			if( cardlook )
			{
				npcLook = new LookData();
				npcLook.fill( cardlook );
				npcLook.applyBaseLook(playerLook);
				
				npcLook.applyAspect( new LookAspectData( SkinUtils.EYE_STATE, EyeSystem.CASUAL_STILL ) );	// TODO :: would like to just apply "_still" suffix if a state has already been set. -bard
			}
			else
			{
				npcLook = playerLook;
			}
			return npcLook;
		}
		
		private const LOADER_SPIN_SPEED:Number = 200;
		private const Y_OFFSET:Number = 15;
		private const CHAR_SIZE:Number = 1;
		private const CHAR_LOAD_DELAY:uint = 6;
		private var _loadingWheel:Entity;
		private var _charContainer:Sprite;
		private var _fitHead:Boolean = true;
		private var _widthConstraint:Number = 200;
		private var _heightConstraint:Number = 200;
	}
}