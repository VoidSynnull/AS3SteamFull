package game.ui.popup
{
	import com.poptropica.AppConfig;
	import com.poptropica.interfaces.IProductStore;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.creators.ui.ToolTipCreator;
	import game.data.dlc.TransactionRequestData;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	
	public class MembershipPopup extends Popup
	{
		private var _content:MovieClip;
		
		private var _storeSupported : Boolean = false;
		
		private var _productStore :IProductStore;
		
		private const IOS_ITEM_STORE_PREFIX:String = "com.pearsoned.poptropica.membership.";
		private const ANDROID_ITEM_STORE_PREFIX:String = "air.com.pearsoned.poptropica.";
		
		private const MEMBERSHIP_PURCHASED:String	= "MembershipPurchased";
		private const MEMBERSHIP_SELECTED:String	= "MembershipSelected";
		private const MEMBERSHIP_STATUS:String		= "MembershipStatus";
		private const MEMBERSHIP_FAILED:String		= "MembershipFailed";
		
		private var membershipTypeToTrack:String;
		
		public function MembershipPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			groupPrefix = "ui/popups/";
			screenAsset = "membershipPopup.swf";
			darkenBackground = true;
			super.init(container);
			load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			_content = screen["content"];
			_content.x = shellApi.viewportWidth/2;
			_content.y = shellApi.viewportHeight/2;
			
			//DisplayUtils.fitDisplayToScreen(this, _content);
			
			setupStoreSupport();
			
			for(var i:int = 1; i <= 3; i++)
			{
				var clip:MovieClip = _content["m"+i];
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
				var interaction:Interaction = InteractionCreator.addToEntity(entity,[InteractionCreator.CLICK]);
				interaction.click.add(Command.create(clickMembershipOption, i));
				ToolTipCreator.addToEntity(entity);
			}
			
			loadCloseButton();
		}
		
		private function setupStoreSupport() : void
		{
			_storeSupported = false;
			
			if(PlatformUtils.isMobileOS)
			{
				if(AppConfig.iapOn)
				{
					_productStore = shellApi.dlcManager.productStore;
					if(_productStore)
					{
						_storeSupported = true;
						if(!_productStore.isSupported())
						{			
							trace("MembershipPopup :: checkStoreSupport : productStore is not available, can't instantiate");
							_storeSupported = false;
							return;
						}
						
						if(!_productStore.isAvailable())
						{
							trace("MembershipPopup :: checkStoreSupport : itunes or In APP Purchasing is disabled on this device");
							//_storeSupported = false
						}
					}
				}
				else	
				{ 
					trace("MembershipPopup :: checkStoreSupport : iapOn is false, no productStore"); 
				}
			}
			else	
			{ 
				trace("MembershipPopup :: checkStoreSupport : productStore is only for Mobile Devices"); 
			}
		}
		
		private function clickMembershipOption(entity:Entity, option:int):void
		{
			var request:TransactionRequestData;
			var requestId:String;
			trace("buy membership option: " + option);
			
			switch(option)
			{
				case 1:
				{
					//1 month
					requestId = PlatformUtils.isIOS?"months1":"onemonth";
					membershipTypeToTrack = "1Month";
					break;
				}
				case 2:
				{
					//3 month
					requestId = PlatformUtils.isIOS?"months3":"threemonth";;
					membershipTypeToTrack = "3Month";
					break;
				}	
				default:
				{
					//6 month
					requestId = PlatformUtils.isIOS?"months6":"sixmonth";;
					membershipTypeToTrack = "6Month";
					break;
				}
			}
			
			if(_storeSupported)
			{
				SceneUtil.lockInput(this);
				var prefix:String = PlatformUtils.isIOS?IOS_ITEM_STORE_PREFIX:ANDROID_ITEM_STORE_PREFIX;
				request = TransactionRequestData.requestPurchase(prefix+requestId, onComplete);
				_productStore.setManualMode(true);
				_productStore.setProfile(shellApi.profileManager.active);
				_productStore.requestTransaction(request);
				
				shellApi.track(MEMBERSHIP_SELECTED, membershipTypeToTrack);
			}
			else
			{
				trace("store not supported");
			}
		}
		
		private function onComplete(request:TransactionRequestData, state:String):void
		{
			SceneUtil.lockInput(this, false);
			//losses id along the way for some reason
			_productStore.setManualMode(false);
			var popup:ConfirmationDialogBox;
			if(state == TransactionRequestData.STATE_COMPLETED)
			{
				shellApi.profileManager.active.RefreshMembershipStatus(shellApi);
				popup = addChildGroup(new ConfirmationDialogBox(1,"Your membership was purchased successfully", close)) as ConfirmationDialogBox;
				shellApi.track(MEMBERSHIP_PURCHASED, membershipTypeToTrack);
			}
			else
			{
				popup = addChildGroup(new ConfirmationDialogBox(1,"There was a problem with your transaction. Pleas try again.")) as ConfirmationDialogBox;
				shellApi.track(MEMBERSHIP_FAILED, membershipTypeToTrack, request.message.replace("\n"," "));
			}
			// don't forget to init
			popup.init(screen);
		}
	}
}