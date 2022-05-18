package game.ui.hud
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Sleep;
	import game.components.ui.Button;
	import game.components.ui.HUDIcon;
	import game.creators.ui.ButtonCreator;
	import game.scene.template.SceneUIGroup;
	import game.scenes.hub.store.Store;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.settings.SettingsPopup;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;

	public class HudMap extends Hud
	{
		
		public function HudMap(container:DisplayObjectContainer=null) 
		{
			super( container );
		}
		
		override public function loaded():void 
		{
			super.setupScreen();
			initHud();
			super.groupReady();
		}	

		override protected function initHud():void 
		{
			var topRowClip:MovieClip = screen.topRow as MovieClip;
			_topRow = EntityUtils.createSpatialEntity( this, topRowClip );
			
			// remove unused buttons
			topRowClip.removeChild(topRowClip.hudBtn);
			topRowClip.removeChild(topRowClip.realmsBtn);
			//topRowClip.removeChild(topRowClip.friendsBtn);
			topRowClip.removeChild(topRowClip.costumizerBtn);
			topRowClip.removeChild(topRowClip.inventoryBtn);
			topRowClip.removeChild(topRowClip.mapBtn);
			topRowClip.removeChild(topRowClip.audioBtn);
			screen.removeChild(screen.bottomRow);
			screen.removeChild(screen.cameraIcon);
			
			// NOTE :: Order buttons are create is important			
			// create settings button
			_settingsBtn = createHudButton( topRowClip.settingsBtn, 0, SETTINGS, null, onSettingsClick );
			
			// create settings button
			var btnClip:MovieClip = topRowClip.storeBtn;
			btnClip.x = super.shellApi.viewportWidth - ( BUTTON_BUFFER/2 + BUTTON_OFFSET );
			_storeBtn = createHudButton( btnClip, 0, STORE, null, onStoreClick );
			
			// create home button
			btnClip = topRowClip.homeBtn;
			btnClip.x = super.shellApi.viewportWidth - ( BUTTON_BUFFER * 1.5 + BUTTON_OFFSET );
			_homeBtn = createHudButton( btnClip, 0, HOME, null, onHomeClick );
			
			// create background button to pick up click outside of hud.
			_background = new Entity();
			var bgClip:MovieClip = new MovieClip();
			bgClip.graphics.beginFill(0x000000);
			bgClip.graphics.drawRect(0, 0, shellApi.viewportWidth, shellApi.viewportHeight);
			bgClip.graphics.endFill();
			
			_backgroundTint = super.convertToBitmap( bgClip );
			bgClip.alpha = darkenAlpha;
			super.groupContainer.addChildAt(bgClip, 0);
			_background.add( new Display( bgClip ) );
			bgClip.visible = false;
			var interaction:Interaction = InteractionCreator.addToEntity( _background, [ InteractionCreator.CLICK ], bgClip );
			interaction.click.add( onBGClicked );
			super.addEntity( _background );
			
			//hideDarken(true);
		}
		
		/**
		 * Creates a standard hud button, adding necessary components.
		 * @param displayObject
		 * @param index
		 * @param name
		 * @param startX
		 * @param handler
		 * @return 
		 */
		override protected function createHudButton( displayObject:DisplayObjectContainer, index:int, name:String, startSpatial:Spatial, handler:Function = null, bitmap:Boolean = true ):Entity 
		{
			var btnEntity:Entity = ButtonCreator.createButtonEntity( displayObject, this, handler, null, null, null, false, bitmap );
			btnEntity.name = name + BUTTON;
			btnEntity.add( new Sleep(false, true) );
			btnEntity.add( new HUDIcon() );
			_buttons.push( btnEntity );
			return btnEntity;
		}
		
		/**
		 * Disable/Enable Hud buttons.
		 * @param isEnable
		 * @param includeBG
		 * @param excludeButton
		 */
		override public function enableHUDButtons( isEnable:Boolean = true, includeBG:Boolean=true, excludeButton:Entity = null ):void 
		{
			// enable lower row buttons
			disableBottomBtns( !isEnable );
			
			// enable bg
			// enable bg
			if (includeBG && _background ) 
			{
				EntityUtils.getDisplayObject(_background).mouseEnabled = isEnable;
				hideDarken( isEnable );
			}

			// enable hud buttons
			var buttonEntity:Entity;
			var hudButton:HUDIcon;
			for (var i:int=0; i<_buttons.length; i++) 
			{
				buttonEntity = _buttons[i];
				// check for excluded button
				if( buttonEntity == excludeButton )
				{
					continue;
				}
				
				hudButton = buttonEntity.get( HUDIcon );
				if( hudButton && !hudButton.disabled )
				{
					Button( buttonEntity.get(Button) ).isDisabled = !isEnable;
					Interaction( buttonEntity.get( Interaction ) ).lock = !isEnable;
				}
			}
		}
		
		/**
		 * Creates a standard Dialog box for the hud 
		 * @param numButtons
		 * @param dialogText
		 * @param confirmHandler
		 * @param cancelHandler
		 * @param createClose
		 * @return  
		 */
		override protected function createHudDialogBox( numButtons:int = 2, dialogText:String = "", confirmHandler:Function = null, cancelHandler:Function = null, createClose:Boolean = true):ConfirmationDialogBox 
		{
			var dialogBox:ConfirmationDialogBox = this.parent.addChildGroup( new ConfirmationDialogBox( numButtons, dialogText, confirmHandler, cancelHandler, createClose )) as ConfirmationDialogBox;
			dialogBox.darkenBackground = false;
			dialogBox.pauseParent = true;
			dialogBox.popupRemoved.addOnce( enableHUDButtons );
			dialogBox.init( super.groupContainer );
			enableHUDButtons(false);
			return dialogBox;
		}
		
		override protected function onSettingsClick( btn:Entity ):void 
		{
			// if doesn't exists, create new popup
			if (!_settingsPanel)
			{
				super.playClick();
				shellApi.track(SETTINGS + OPENED, null, null, SceneUIGroup.UI_EVENT);
				
				_settingsPanel = new SettingsPopup();
				_settingsPanel.darkenBackground = false;
				_settingsPanel.pauseParent = true;
				_settingsPanel.popupRemoved.addOnce( super.closeSettings );
				this.parent.addChildGroup(_settingsPanel);
				_settingsPanel.init( super.groupContainer );
				enableHUDButtons(false, true, _settingsBtn );			
			} 
			else
			{
				// if does exist, close
				super.playCancel();
				shellApi.track(SETTINGS + CLOSED, null, null, SceneUIGroup.UI_EVENT);
				_settingsPanel.close();
			}
		}
		
		/**
		 * Open the store
		 * @param btn
		 */
		override protected function openStore():void 
		{
			shellApi.track(STORE + OPENED, null, null, SceneUIGroup.UI_EVENT);
			// do we need a notification popup here? - bard
			super.shellApi.loadScene(Store);
		}
	}
}