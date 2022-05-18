package game.ui.popup
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.ui.Button;
	import game.components.ui.CardItem;
	import game.creators.ui.ButtonCreator;
	import game.data.PlayerLocation;
	import game.data.island.IslandEvents;
	import game.data.profile.ProfileData;
	import game.data.ui.TransitionData;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.scene.template.ui.CardGroup;
	import game.scenes.hub.store.Store;
	import game.scenes.hub.town.Town;
	import game.scenes.map.map.Map;
	import game.ui.card.CardView;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.DisplayAlignment;
	import game.util.DisplayPositions;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.TextUtils;
	
	import org.osflash.signals.Signal;
	
	public class IslandEndingPopup extends Popup
	{
		private var _islandXML:XML;
		private var _medallionCardView:CardView;
		private var _numCompletions:uint = 0;

		/** vertical start position of buttons */
		protected var buttonY:int = 182;	
		
		protected var message:String = "You've completed an island quest and earned an island medallion"
		
		public var buttonOrder:Array = ["continue", "quest", "island", "store", "rank"];

		public var clicked:Signal;
		public var islandOverride:String = "";
		public var hasBonusQuestButton:Boolean = false;
		public var hasContinueButton:Boolean = false;
		protected var hasPlayButton:Boolean = true;
		protected var hasStoreButton:Boolean = true;
		protected var hasRankButton:Boolean = true;
		/** flag that determines if a close button is created for the popup */
		public var closeButtonInclude:Boolean = false;
		
		public function IslandEndingPopup(container:DisplayObjectContainer = null)
		{
			super(container);
			
			this.id 				= "IslandEndingPopup";
			this.groupPrefix 		= "ui/popups/islandEndingPopup/";
			this.screenAsset 		= "islandEndingPopup.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			clicked = new Signal(Entity);
			this.transitionIn 			= new TransitionData();
			this.transitionIn.duration 	= 0.9;
			this.transitionIn.startPos 	= new Point(0, -super.shellApi.viewportHeight);
			this.transitionIn.endPos 	= new Point(0, 0);
			this.transitionIn.ease 		= Bounce.easeOut;
			this.transitionOut 			= transitionIn.duplicateSwitch(Sine.easeIn);
			this.transitionOut.duration = 0.3;
			super.darkenBackground 		= true;
			
			super.init(container);
			
			this.load();
		}

		public override function destroy():void
		{
			super.destroy();
			clicked.removeAll();
			clicked = null;
		}

		public function getIsland():String
		{
			return DataUtils.isValidStringOrNumber(this.islandOverride) ? this.islandOverride : this.shellApi.island;
		}
		
		override public function load():void
		{
			this.loadFiles(["ui/popups/islandEndingPopup/islandEndingPopup.swf", "scenes/" + this.getIsland() + "/island.xml"], true, true, this.loaded);
		}
		
		override public function loaded():void
		{
			super.loaded();

			this._islandXML = this.getData("scenes/" + this.getIsland() + "/island.xml", true, true);
			
			var content:DisplayObjectContainer = this.screen.content;
			var rectangle:Rectangle = content.getBounds(content.parent);
			/*
			Adding buffer space around the letterboxing so the popup doesn't
			fill the WHOLE screen, but it still resizes proportionally.
			*/
			
			rectangle.inflate(50, 50);
			this.letterbox(content, rectangle, false);
			
			this.setupMedallionCard();
			this.setupPlayerName();
			this.setupCompletedIslandText();
			this.setupContinueButton();
			this.setupQuestButton();
			this.setupPlayButton();
			this.setupStoreButton();
			this.setupRankButton();
			this.setupButtonOrder();
			this.setupCreditBag();
			
			if( this.closeButtonInclude )
			{
				super.loadCloseButton(DisplayPositions.TOP_RIGHT, (shellApi.viewportWidth - content.width)/2 + 10, (shellApi.viewportHeight - content.height)/2 + 10 );
			}
		}
		
		private function setupButtonOrder():void
		{
			var y:Number = buttonY;
			
			for(var index:int = 0; index < this.buttonOrder.length; ++index)
			{
				var entity:Entity = this.getEntityById(this.buttonOrder[index] + "Button");
				
				if(entity)
				{
					var spatial:Spatial = entity.get(Spatial);
					spatial.y = y;
					
					var displayObject:DisplayObject = Display(entity.get(Display)).displayObject;
					var bounds:Rectangle = displayObject.getBounds(displayObject.parent);
					
					y += bounds.height + 5;
				}
			}
		}
		
		protected function setupContinueButton():void
		{
			var clip:MovieClip = this.screen.content.continueButton;
			
			if(this.hasContinueButton && !this.hasBonusQuestButton)
			{
				var entity:Entity = ButtonCreator.createButtonEntity(clip, this, onContinueClicked, null, null, null, false);
				entity.add(new Id(clip.name));
			}
			else
			{
				clip.parent.removeChild(clip);
			}
		}
		
		protected function onContinueClicked(entity:Entity):void
		{
			clicked.dispatch(entity);
			this.close();
		}
		
		private function setupQuestButton():void
		{
			var clip:MovieClip = this.screen.content.questButton;
			
			if(this.hasBonusQuestButton)
			{
				var entity:Entity = ButtonCreator.createButtonEntity(clip, this, onQuestClicked, null, null, null, false);
				entity.add(new Id(clip.name));
			}
			else
			{
				clip.parent.removeChild(clip);
			}
		}
		
		private function onQuestClicked(entity:Entity):void
		{
			clicked.dispatch(entity);
			this.close();
		}
		
		private function setupMedallionCard():void
		{
			if(DataUtils.validString(String(this._islandXML.medallion)))
			{
				var cardGroup:CardGroup = this.getGroupById(CardGroup.GROUP_ID) as CardGroup;
				if(!cardGroup)
				{
					cardGroup = this.addChildGroup(new CardGroup()) as CardGroup;
				}
				
				//_medallionCardView = cardGroup.createCardViewByItem(this, this.screen.content, String(this._islandXML.medallion), this.shellApi.island, null, onCardLoaded);
				//trace(this.screen.content, this._islandXML.medallion, this.getIsland());
				_medallionCardView = cardGroup.createCardViewByItem(this, this.screen.content, String(this._islandXML.medallion), this.getIsland(), null, onCardLoaded);
				_medallionCardView.hide(true);
			}
		}
		
		public function onCardLoaded(cardItem:CardItem):void
		{
			_medallionCardView.bitmapCardBack(CardGroup.CARD_BOUNDS, 1);
			_medallionCardView.displayCardItem();
			_medallionCardView.hide(false);
			
			var area:Rectangle = this.screen.content.medallionCard.getBounds(this.screen.content);
			
			var display:Display = _medallionCardView.cardEntity.get(Display);
			
			//Do smoothing so the card looks decent.
			cardItem.bitmapWrapper.bitmap.smoothing = true;
			
			DisplayAlignment.fitAndAlign(display.displayObject, area);
			EntityUtils.syncSpatial(_medallionCardView.cardEntity.get(Spatial), display.displayObject);
		}
		
		private function setupPlayerName():void
		{
			var textField:TextField = TextUtils.refreshText(this.screen.content["playerName"]);
			textField.text = this.shellApi.profileManager.active.avatarName;
		}
		
		protected function setupCompletedIslandText():void
		{
			var textField:TextField = TextUtils.refreshText(this.screen.content["completedIsland"]);
			textField.text = message;
			
			if(!PlatformUtils.isMobileOS)
			{
				var profile:ProfileData = shellApi.profileManager.active;
				//for (var p:String in profile.islandCompletes) trace(p, "completed", profile.islandCompletes[p]);
				_numCompletions = 1;
				if (!profile.isGuest)
				{
					_numCompletions = DataUtils.useNumber(String(profile.islandCompletes[getIsland()]), 1);
				}
				if (_numCompletions < 2)
				{
					textField.text += " and 150 credits to spend in the store";
				}
			}
			
			textField.text += "!";
		}
		
		protected function setupPlayButton():void
		{
			var clip:MovieClip = this.screen.content.islandButton;
			if( hasPlayButton )
			{
				var entity:Entity = ButtonCreator.createButtonEntity(clip, this, onIslandButtonClicked, null, null, null, false);
				entity.add(new Id(clip.name));
				
				var eventsClass:Class = ClassUtils.getClassByName(this._islandXML.eventsClass);
				if(eventsClass)
				{
					var currentIslandEvents:IslandEvents = new eventsClass();
					
					if(currentIslandEvents.nextEpisodeEvents)
					{
						var nextIslandEvents:IslandEvents = new currentIslandEvents.nextEpisodeEvents();
						
						if(nextIslandEvents.accessible)
						{
							if(!nextIslandEvents.earlyAccess || this.shellApi.profileManager.active.isMember)
							{
								var textField:TextField = TextUtils.refreshText(clip["description"]);
								textField.text = "Play Next Episode!";
								Button(entity.get(Button)).value = nextIslandEvents.island;
							}
						}
					}
				}
				else
				{
					trace("IslandEndingPopup :: setupPlayButton() :: EventsClass could not be created from <", this._islandXML.eventsClass, ">.");
				}
			}
			else
			{
				clip.parent.removeChild(clip);
			}
		}
		
		protected function onIslandButtonClicked(entity:Entity):void
		{
			clicked.dispatch(entity);
			var island:String = Button(entity.get(Button)).value;
			if(island)
			{
				this.returnToIslandAndScene(island);
			}
			else
			{
				this.shellApi.loadScene(Map);
			}
		}
		
		private function returnToIslandAndScene(island:String):void
		{
			var lastLocation:PlayerLocation = this.shellApi.profileManager.active.lastScene[island];
			//If we have a last location, put them there.
			if(lastLocation)
			{
				this.loadSceneAS3OrAS2(island, lastLocation.scene, lastLocation.locX, lastLocation.locY, lastLocation.direction == "L" ? "left" : "right");
			}
			//If not, we'll load the island's default starting scene and location.
			else
			{
				this.shellApi.loadFile(super.shellApi.dataPrefix + "scenes/" + island + "/island.xml", this.islandXMLLoaded);
			}
		}
		
		private function islandXMLLoaded(xml:XML):void
		{
			if(!xml) return;
			
			var island:String = String(xml.island);
			
			var firstScene:XML = XML(xml.firstScene);
			
			var scene:String 		= String(firstScene.scene);
			var x:Number 			= Number(firstScene.x);
			var y:Number 			= Number(firstScene.y);
			var direction:String 	= String(firstScene.direction);
			
			this.loadSceneAS3OrAS2(island, scene, x, y, direction);
		}
		
		private function loadSceneAS3OrAS2(island:String, scene:String, x:Number, y:Number, direction:String):void
		{
			//Go to AS3 (AS2 removed)
			if(scene.indexOf(".") > -1)
			{
				var sceneClass:Class = ClassUtils.getClassByName(scene);
				this.shellApi.loadScene(sceneClass, x, y, direction);
			}
			else
			{
				shellApi.loadScene(Town);
			}
		}
		
		private function setupStoreButton():void
		{
			var clip:MovieClip = this.screen.content.storeButton;
			if( hasStoreButton )
			{	
				var entity:Entity = ButtonCreator.createButtonEntity(clip, this, onStoreButtonClicked, null, null, null, false);
				entity.add(new Id(clip.name));
			}
			else
			{
				clip.parent.removeChild(clip);
			}
		}
		
		private function onStoreButtonClicked(entity:Entity):void
		{
			clicked.dispatch(entity);
			this.shellApi.loadScene(Store);
		}
		
		private function setupRankButton():void
		{
			var clip:MovieClip = this.screen.content.rankButton;
			if(hasRankButton && !PlatformUtils.isMobileOS && DataUtils.validString(String(this._islandXML.playerMap)))
			{
				ButtonCreator.createButtonEntity(clip, this, onRankButtonClicked, null, null, null, false);
			}
			else
			{
				clip.parent.removeChild(clip);
			}
		}
		
		private function onRankButtonClicked(entity:Entity):void
		{
			clicked.dispatch(entity);
			//Pull the rank URL from XML
			var url:String = String(this._islandXML.playerMap);
			navigateToURL(new URLRequest(url), "_blank");
		}
		
		private function setupCreditBag():void
		{
			var clip:MovieClip = this.screen.content["creditBag"];
			if(PlatformUtils.isMobileOS || _numCompletions > 1)
			{
				clip.parent.removeChild(clip);
			}
		}
	}
}
