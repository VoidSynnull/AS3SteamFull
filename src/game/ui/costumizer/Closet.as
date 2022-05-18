package game.ui.costumizer
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.Skin;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Walk;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.PlayerLook;
	import game.data.comm.PopResponse;
	import game.data.ui.TransitionData;
	import game.managers.LanguageManager;
	import game.proxy.DataStoreRequest;
	import game.proxy.IDataStore2;
	import game.scene.template.CharacterGroup;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.popup.Popup;
	import game.util.Alignment;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class Closet extends Popup
	{
		public const MAX_LOOKS:int = 30;
		public const MODEL_SPACING:int = 300;
		public const MODEL_SCALE:Number = 1.2;
		public const SCROLL_TIME:Number = 0.6;
		private var _shadow:BitmapData;
		
		private var _converter:LookConverter = new LookConverter();
		
		private var _message:TextField;
		private var _trashcanButton:Entity;
		private var _membershipButton:Entity;
		
		private var _characterGroup:CharacterGroup;
		
		private var _closetLooks:Vector.<ClosetLook> = new Vector.<ClosetLook>(); //AS2
		
		private var _models:Vector.<Entity> = new Vector.<Entity>();
		private var _closetIndex:int = 0;
		
		private var _tween:Tween;
		
		private var _scrollCount:uint = 0;
		private var _scrollLeft:Entity;
		private var _scrollRight:Entity;
		private var _selectLook:Entity;
		
		public var closetLookClicked:Signal = new Signal(LookData);
		
		public function Closet(container:DisplayObjectContainer = null)
		{
			super(container);
			
			this.id 				= "ClosetPopup";
			this.groupPrefix 		= "ui/costumizer/";
			this.screenAsset 		= "closet.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function destroy():void
		{
			this._shadow.dispose();
			this._shadow = null;
			
			this.closetLookClicked.removeAll();
			
			if (!shellApi.needToStoreOnServer())
			{
				var playerLooks:Vector.<PlayerLook> = new Vector.<PlayerLook>();
				for each(var look:ClosetLook in this._closetLooks)
				{
					playerLooks.push(this._converter.playerLookFromLookData(look.lookData));
				}
				this.shellApi.profileManager.active.closetLooks = playerLooks;
			}
			
			this.shellApi.saveGame();
			
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			this.transitionIn 			= new TransitionData();
			this.transitionIn.duration 	= 0.9;
			this.transitionIn.startPos 	= new Point(0, -super.shellApi.viewportHeight);
			this.transitionIn.endPos 	= new Point(0, 0);
			this.transitionIn.ease 		= Bounce.easeOut;
			this.transitionOut 			= transitionIn.duplicateSwitch(Sine.easeIn);
			this.transitionOut.duration = 0.3;
			
			super.init(container);
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			this._tween = this.getGroupEntityComponent(Tween);
			
			this.setupBackground();
			this.setupCloseButton();
			this.setupHeader();
			this.setupMessage();
			this.setupScrolling();
			this.setupClosetLooks();
			this.setupLookSelection();
			this.setupTrashcan();
			this.setupMembership();
		}
		
		private function setupBackground():void
		{
			var clip:MovieClip 	= this.screen.background;
			clip.width 			= this.shellApi.viewportWidth;
			clip.height 		= this.shellApi.viewportHeight;
			this.convertToBitmap(clip);
		}
		
		private function setupCloseButton():void
		{
			var clip:MovieClip = this.screen.close;
			clip.x = this.shellApi.viewportWidth - 40;
			ButtonCreator.createButtonEntity(clip, this, this.onCloseClicked);
		}
		
		private function onCloseClicked(entity:Entity):void
		{
			this.handleCloseClicked();
		}
		
		private function setupLookSelection():void
		{
			this._selectLook = ButtonCreator.createButtonEntity(this.screen.selectLook, this, this.onLookSelected);
		}
		
		private function onLookSelected(entity:Entity):void
		{
		
				entity.get(Interaction).lock = true;
				
				this.closetLookClicked.dispatch(this._closetLooks[this._closetIndex].lookData);
				
				this.close();
		}
		
		private function setupClosetLooks():void
		{
			if (isNaN(shellApi.profileManager.active.dbid))
			{
				var playerLooks:Vector.<PlayerLook> = this.shellApi.profileManager.active.closetLooks;
				for each(var playerLook:PlayerLook in playerLooks)
				{
					var closetLook:ClosetLook 	= new ClosetLook();
					closetLook.lookData 		= this._converter.lookDataFromPlayerLook(playerLook);
					closetLook.lookData.fillWithEmpty();
					this._closetLooks.push(closetLook);
				}
				this.setupCharacters();
			}
			else
			{
				var req:DataStoreRequest = DataStoreRequest.closetLooksRetrievalRequest();
				req.requestTimeoutMillis = 1000;
				//shellApi.siteProxy.retrieve(DataStoreRequest.closetLooksRetrievalRequest(), closetLooksReceived);
				(shellApi.siteProxy as IDataStore2).call(req, closetLooksReceived);
			}
		}
		
		private function closetLooksReceived(response:PopResponse):void
		{
			if (response.succeeded) {
				// closetLooks returned in form of: [{lookItemID:lookData}, {lookItemID:lookData}, ...]
				var looks:Array = (response && response.data && response.data.closetLooks) ? response.data.closetLooks : [];

				for each(var lookObject:Object in looks)
				{
					//There should only be 1 single property in this object! Just don't know what the name is...
					for(var lookItemID:String in lookObject)
					{
						var lookData:LookData = lookObject[lookItemID];
						
						var closetLook:ClosetLook 	= new ClosetLook();
						closetLook.lookItemID 		= lookItemID;
						closetLook.lookData 		= lookData;
						closetLook.lookData.setValue(SkinUtils.EYES, "eyes");
						closetLook.lookData.fillWithEmpty();
						this._closetLooks.push(closetLook);
					}
				}
			} else {
				trace("Closet::closetLooksReceived() fail:", response);
			}
			
			this.setupCharacters();
		}
		
		private function setupCharacters():void
		{
			this._shadow = BitmapUtils.createBitmapData(this.screen.shadow);
			
			this._characterGroup = super.getGroupById("characterGroup") as CharacterGroup;
			if(!this._characterGroup)
			{
				this._characterGroup = super.addChildGroup(new CharacterGroup()) as CharacterGroup;
			}
			
			var closetDummy:Entity;
			for(var index:int = -1; index < 3; ++index)
			{
				var lookData:LookData = (index > -1 && index < this._closetLooks.length) ? this._closetLooks[index].lookData : new LookData();
				
				closetDummy = this._characterGroup.createDummy("closetModel" + (index + 2), lookData, "left", CharacterCreator.VARIANT_HUMAN, this.screen, this, Command.create(modelLoaded, index), true, MODEL_SCALE);
				var skin:Skin = new Skin();
				skin.allowSpecialAbilities = false;
				closetDummy.add(skin);
			}
		}
		
		private function modelLoaded(entity:Entity, index:int):void
		{
			entity.get(Spatial).y = this.shellApi.viewportHeight * 0.5 + 70;
			Alignment.leftAtIndex(entity.get(Spatial), "x", this.shellApi.viewportWidth * 0.5, MODEL_SPACING, index);
			
			var display:DisplayObjectContainer = entity.get(Display).displayObject;
			display.parent.setChildIndex(display, 1);
			
			var sprite:Sprite 	= BitmapUtils.createBitmapSprite(this.screen.shadow, 1, null, true, 0, this._shadow);
			sprite.x 			= 0;
			sprite.y 			= 105;
			display.addChildAt(sprite, 0);
			
			//God damn Sleep ruining everything! AAAARRRGGHHH!!!
			entity.remove(Sleep);
			entity.sleeping = false;
			
			entity.get(Display).visible = (index > -1 && index < this._closetLooks.length);
			
			entity.add(new ClosetIndex(index));
			
			this._models.push(entity);
		}
		
		private function setupScrolling():void
		{
			var interaction:Interaction;
			
			this._scrollLeft = EntityUtils.createSpatialEntity(this, this.screen.moveLeft);
			interaction = InteractionCreator.addToEntity(this._scrollLeft, [InteractionCreator.CLICK]);
			interaction.click.add(this.moveCharactersRight);
			
			this._scrollRight = EntityUtils.createSpatialEntity(this, this.screen.moveRight);
			interaction = InteractionCreator.addToEntity(this._scrollRight, [InteractionCreator.CLICK]);
			interaction.click.add(this.moveCharactersLeft);
		}
		
		private function moveCharactersRight(entity:Entity):void
		{
			if(this._scrollCount > 0) return;
			
			if(this._closetIndex - 1 > -1)
			{
				this._scrollLeft.get(Interaction).lock = true;
				this._scrollRight.get(Interaction).lock = true;
				
				for each(var model:Entity in this._models)
				{
					CharUtils.setDirection(model, true);
					CharUtils.setAnim(model, Walk);
					
					var spatial:Spatial = model.get(Spatial);
					if(spatial.x + MODEL_SPACING > this.shellApi.viewportWidth * 0.5 + MODEL_SPACING * 2)
					{
						spatial.x = this.shellApi.viewportWidth * 0.5 - MODEL_SPACING * 2;
						
						var index:ClosetIndex = model.get(ClosetIndex);
						index.index = this._closetIndex - 2;
						
						if(index.index > -1)
						{
							SkinUtils.applyLook(model, this._closetLooks[index.index].lookData);
							model.get(Display).visible = true;
						}
						else
						{
							model.get(Display).visible = false;
						}
					}
					
					this._scrollCount = 4;
					this._tween.to(spatial, SCROLL_TIME, {x:spatial.x + MODEL_SPACING, onComplete:this.stopScroll});
				}
				
				--this._closetIndex;
			}
		}
		
		private function moveCharactersLeft(entity:Entity):void
		{
			if(this._scrollCount > 0) return;
			
			if(this._closetIndex + 1 < this._closetLooks.length)
			{
				this._scrollLeft.get(Interaction).lock = true;
				this._scrollRight.get(Interaction).lock = true;
				
				for each(var model:Entity in this._models)
				{
					CharUtils.setDirection(model, false);
					CharUtils.setAnim(model, Walk);
					
					var spatial:Spatial = model.get(Spatial);
					if(spatial.x - MODEL_SPACING < this.shellApi.viewportWidth * 0.5 - MODEL_SPACING * 2)
					{
						spatial.x = this.shellApi.viewportWidth * 0.5 + MODEL_SPACING * 2;
						
						var index:ClosetIndex = model.get(ClosetIndex);
						index.index = this._closetIndex + 2;
						
						if(index.index < this._closetLooks.length)
						{
							SkinUtils.applyLook(model, this._closetLooks[index.index].lookData);
							model.get(Display).visible = true;
						}
						else
						{
							model.get(Display).visible = false;
						}
					}
					
					this._scrollCount = 4;
					this._tween.to(spatial, SCROLL_TIME, {x:spatial.x - MODEL_SPACING, onComplete:this.stopScroll});
				}
				
				++this._closetIndex;
			}
		}
		
		private function stopScroll():void
		{
			--this._scrollCount;
			if(this._scrollCount == 0)
			{
				for each(var model:Entity in this._models)
				{
					CharUtils.setAnim(model, Stand);
				}
				
				this._scrollLeft.get(Interaction).lock = false;
				this._scrollRight.get(Interaction).lock = false;
			}
		}
		
		private function setupHeader():void
		{
			this.screen.header.x = this.shellApi.viewportWidth * 0.5;
		}
		
		private function setupMessage():void
		{
			var format:TextFormat 	= new TextFormat();
			format.align 			= TextFormatAlign.CENTER;
			format.bold 			= true;
			format.font 			= "CreativeBlock BB";
			format.size 			= 21;
			format.color 			= 0xFFFFFF;
			
			this._message 					= new TextField();
			this._message.setTextFormat(format);
			this._message.defaultTextFormat = format;
			this._message.mouseEnabled 		= false;
			this._message.multiline 		= true;
			this._message.embedFonts		= true;
			this._message.antiAliasType 	= AntiAliasType.NORMAL;
			this._message.width 			= this.shellApi.viewportWidth;
			this._message.x 				= 0;
			this._message.y					= this.shellApi.viewportHeight - 40;
			

			
			this.screen.addChild(this._message);
		}
		
		private function setupTrashcan():void
		{
			var clip:MovieClip = this.screen.trashcan;
			clip.x = this.shellApi.viewportWidth * 0.5;
			clip.y = this.shellApi.viewportHeight - 75;
			this._trashcanButton = ButtonCreator.createButtonEntity(clip, this, this.onTrashcanClicked);
		}
		
		private function onTrashcanClicked(entity:Entity):void
		{
			if(this._closetLooks.length > 0)
			{
				var defaultText:String = "Are you sure you want to delete this look?";
				var text:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.closetPopup.deleteLook", defaultText);
				
				var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(2, text, deleteLook)) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(this.groupContainer);
			}
		}
		
		private function deleteLook():void
		{
			if (shellApi.needToStoreOnServer())
			{
				shellApi.siteProxy.store(DataStoreRequest.closetLookDeletionRequest(this._closetLooks[this._closetIndex].lookItemID));
			}
			this._closetLooks.splice(this._closetIndex, 1);
			
			var shiftDown:Boolean = false;
			
			if(this._closetIndex == this._closetLooks.length)
			{
				--this._closetIndex;
				shiftDown = true;
			}
			
			var playerLook:LookData = SkinUtils.getLook(this.shellApi.player);
			
			for each(var model:Entity in this._models)
			{
				var index:ClosetIndex = model.get(ClosetIndex);
				
				if(shiftDown)
				{
					--index.index;
				}
				
				if(index.index > -1 && index.index < this._closetLooks.length)
				{
					var lookData:LookData = this._closetLooks[index.index].lookData;
					
					SkinUtils.applyLook(model, lookData);
					model.get(Display).visible = true;
				}
				else
				{
					model.get(Display).visible = false;
				}
			}
			
			this.shellApi.saveGame();
		}
		
		private function setupMembership():void
		{
			var clip:MovieClip = this.screen.membership;
			clip.x = this.shellApi.viewportWidth * 0.5;
			clip.y = this.shellApi.viewportHeight - 75;
			this._membershipButton = ButtonCreator.createButtonEntity(clip, this, this.onMembershipClicked);
			this._membershipButton.get(Display).visible = false;
		}
		
		private function onMembershipClicked(entity:Entity):void
		{
			
		}
	}
}