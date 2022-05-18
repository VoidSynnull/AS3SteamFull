/**
 * Holds all the standard scene ui in a single group.
 */

package game.scene.template 
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import engine.group.DisplayGroup;
	import engine.managers.SoundManager;
	
	import game.systems.SystemPriorities;
	import game.systems.ui.ToolTipSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.hud.Hud;
	import game.ui.toolTips.ToolTipView;
	import game.util.PlatformUtils;
	
	public class SceneUIGroup extends DisplayGroup
	{
		public static const RETURN_HOME_CONFIRMATION:uint			= 0;
		public static const OPEN_FRIENDS_CONFIRMATION:uint			= 1;
		public static const OPEN_MAP_CONFIRMATION:uint				= 2;
		public static const OPEN_COSTUMIZER_CONFIRMATION:uint		= 3;
		public static const REGISTRATION_FORM_CONFIRMATION:uint		= 4;
		public static const MEMBERSHIP_TOUR_CONFIRMATION:uint		= 5;
		public static const HAVE_ITEM_MESSAGE:String				= 'You already have that item.';
		public static const CONFIRMATION_PREAMBLE:String			= 'Are you sure you want to ';
		public static const GO_TO_MAIN_STREET:String				= 'go to Main Street?';
		
		public static const REGISTRATION_FORM_MESSAGE:String		= 'You must save your game to make Friends on Poptropica. Save now?'; // Is this used anywhere?
		public static const COSTUMIZER_NOT_READY_MESSAGE:String		= 'The Costumizer is unavailable at this time.';
		public static const UNIMPLEMENTED_FEATURE_MESSAGE:String	= 'Sorry, not available during the beta trial.';
		public static const VH_MEMBER_MESSAGE:String				= "Get this item and play all of Virus Hunter Island with Membership.";
		public static const ALREADY_FRIENDS:String					= "You are already friends with that user.";
		public static const LEAVING_POP:String						= "Are you sure you want to leave Poptropica?";
		public static const CANT_FRIEND_IF_NOT_SAVED:String			= "You must save your game to make Friends on Poptropica.";
		public static const CONNECT_TO_INTERNET:String				= 'You must be connected to the internet to continue.';
		public static const MEMBER_PET:String						= "Get this pet with membership.";
		public static const MUST_HAVE_PET:String					= "You must have an active pet to accessorize.";
		public static const NO_NPCS_TO_SELECT:String				= "No characters available to costumize from.";
	
		// brain tracking events
		public static const UI_EVENT:String								= 'uiEvent';	// this is the campaign parameter

		public static const OPEN_COSTUMIZER_CONFIRMED:String			= 'openCostumizerConfirmed';
		public static const OPEN_COSTUMIZER_CANCELED:String				= 'openCostumizerCanceled';
		public static const OPEN_COSTUMIZER_SATCHEL_DISMISSED:String	= 'openCostumizerSatchelDismissed';
		public static const OPEN_COSTUMIZER_BG_DISMISSED:String			= 'openCostumizerBGDismissed';
		
		
		public static const RETURN_TO_GAME_CONFIRMED:String				= 'returnToMapConfirmed';
		public static const RETURN_TO_GAME_CANCELED:String				= 'returnToMapCanceled';
		public static const RETURN_TO_GAME_BG_DISMISSED:String			= 'returnToMapBGDismissed';
		public static const RETURN_TO_GAME_SATCHEL_DISMISSED:String		= 'returnToMapSatchelDismissed';
		
		public static const RETURN_HOME_CONFIRMED:String				= 'returnHomeConfirmed';
		public static const RETURN_HOME_CANCELED:String					= 'returnHomeCanceled';
		public static const RETURN_HOME_BG_DISMISSED:String				= 'returnHomeBGDismissed';
		public static const RETURN_HOME_SATCHEL_DISMISSED:String		= 'returnHomeSatchelDismissed';
		
		[Inject]
		public var soundManager:SoundManager;
		
		protected var _hud:*;
		public function get hud():Hud 	{ return _hud; }
		public var hudClass:Class = null;
		private var _comfirmer:ConfirmationDialogBox;
		private var _confirmationCode:uint;
		
		public var _labels:Dictionary;
		private var _cameraLayer:Sprite;
		public static const GROUP_ID:String = "ui";
		
		public function get confirmationDialogIsShowing():Boolean { return (null != _comfirmer); }
		
		public function SceneUIGroup(container:DisplayObjectContainer, cameraLayer:Sprite = null) 
		{
			super(container);
			super.id = GROUP_ID;
			
			if(cameraLayer)
			{
				_cameraLayer = cameraLayer;
				_cameraLayer.mouseEnabled = false;
			}
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.init(container);
			
			// subclips should handle mouse events themselves if they need them.
			super.groupContainer.mouseEnabled = false;
			
			// create auto tool tips if on a touch screen device
			if(_cameraLayer && PlatformUtils.isMobileOS)
			{
				setupTooltips();
			}
			
			if( hudClass == null )
			{
				hudClass = shellApi.islandManager.hudGroupClass;
			}
			_hud = super.addChildGroup(new hudClass(super.groupContainer));
			_hud.ready.addOnce(hudLoaded);
		}
		
		private function hudLoaded(hud:*):void
		{		
			super.loaded();
		}
		
		private function setupTooltips():void
		{
			var toolTipView:ToolTipView = super.addChildGroup(new ToolTipView(_cameraLayer, super.shellApi.sceneManager.toolTipData)) as ToolTipView;
			toolTipView.id = "toolTipView";
			toolTipView.groupContainer.mouseEnabled = false;
			toolTipView.groupContainer.mouseChildren = false;
			toolTipView.addSystem(new ToolTipSystem(), SystemPriorities.moveComplete);
		}
		
		///////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////// LOGOUT ///////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////
		
		/**
		 * 
		 * @param message - this string should come from config data for i18n
		 * 
		 */
		public function askForConfirmation( message:String, confirmHandler:Function = null, cancelHandler:Function = null ):void 
		{
			// special cases
			switch (message)
			{
				case HAVE_ITEM_MESSAGE:
				case ALREADY_FRIENDS:
				case CANT_FRIEND_IF_NOT_SAVED:
				case CONNECT_TO_INTERNET:
					// clear code so ok button simply closes - used on vending machine
					_confirmationCode = -1;
					break;
				case VH_MEMBER_MESSAGE:
					// used when clicking on members-only vending machine item
					_confirmationCode = MEMBERSHIP_TOUR_CONFIRMATION;
					break;
			}
			
			if (!confirmationDialogIsShowing)
			{
				_comfirmer = addChildGroup( new ConfirmationDialogBox(1, message, confirmHandler, cancelHandler, true)) as ConfirmationDialogBox;
				_comfirmer.closeClicked.add( cancelHandler );	// not sure how we want to deal with this?
				_comfirmer.init(super.groupContainer);
			}
		}
		
		// callback used for clearing confirmation dialog when clicking the cancel button
		public function removeConfirm(object:Object = null):void
		{
			// RLH: removing the confirmer causes a crash so it is commented
			// assuming the popup is already disposed of when it is closed
			//groupManager.remove(_comfirmer);
			_comfirmer = null;
		}
		
		/**
		 * BROWSER ONLY - overridden in Browser specific class 
		 * @param statusMessage - message to display in popup
		 * TODO :: should just have a general message feature. - Bard
		 */
		public function showLogoutStatus( statusMessage:String ):void
		{
			
		}
		
		///////////////////////////////////////////////////////////////////////////////
		////////////////////////////////// MESSAGING //////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Open message dialogue 
		 * @param message
		 * @param confirmHandler
		 * 
		 */
		public function showMessage( message:String, confirmHandler:Function = null ):void 
		{
			if (getGroupById('statusDialog')) 	// do not create new Status Dialog if one is already open
			{
				trace("SceneUIGroup :: prevented logout dialog pileup");
				return;	// one dialog box view is plenty - no stacking
			}
			else
			{
				//var statusDialog:DialogBoxView = super.shellApi.currentScene.addChildGroup( new DialogBoxView( 1, statusMessage, onLogoutStatusClosed ))  as DialogBoxView;
				var messageDialog:ConfirmationDialogBox = super.addChildGroup( new ConfirmationDialogBox( 1, message, confirmHandler ))  as ConfirmationDialogBox;
				messageDialog.id = 'messageDialog';
				messageDialog.darkenBackground = true;
				messageDialog.pauseParent = true;
				
				if( hud )
				{
					hud.show( false );
					if( hud.isOpen )
					{
						messageDialog.darkenBackground = false;
						messageDialog.pauseParent = false;
					}
				}
				
				messageDialog.init( super.groupContainer );
			}
		}
		
		
	}
	
}
