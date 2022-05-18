package game.ui.costumizer 
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.components.entity.character.part.SkinPart;
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.data.ads.AdvertisingConstants;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.ui.login.LoginData;
	import game.ui.login.LoginPanel;
	import game.util.DisplayPositions;

	/**
	 * Costumizer
	 * @author Bard McKinley/Drew Martin
	 */
	public class CostumizerPop extends Costumizer 
	{
		public function CostumizerPop(container:DisplayObjectContainer = null, lookData:LookData = null, ownedLook:Boolean = false, skipNPCCheck:Boolean = false ) 
		{
			super(container, lookData, ownedLook, skipNPCCheck); 
		}
		
		/**
		 * handler for when a npc part is clicked
		 * @param partEntity
		 * @return 
		 */
		override protected function onNpcPartClicked( partEntity:Entity ):void
		{
			var skinPart:SkinPart = partEntity.get(SkinPart);
			addPart( skinPart.id, skinPart.value );
			
			// select corresponding part button
			var partButton:Entity = getPartButtonById( skinPart.id );
			if( partButton )
			{
				Button(partButton.get(Button)).isSelected = true;
			}

			onNPCPartSelected.dispatch(partEntity);
			
			// AD SPECIFIC
			// this is commented out because we can't know the current campaign name for the part
			// a new approach is needed such as adding the campaign name to the part itself
			//checkCampaignPartTrack( skinPart );
		}
		
		/**
		 * AD SPECIFIC
		 * Track if part is limited and being applied from something other than an owned look (card look)
		 * @param skinPart
		 */
		// this is commented out because we can't know the current campaign name for the part
		/*
		private function checkCampaignPartTrack( skinPart:SkinPart ):void
		{
			if ((!_ownedLook) && (skinPart.value.indexOf(AdvertisingConstants.AD_PATH_KEYWORD) != -1))
			{
				// (strip off limited from tracking value)
				AdManager(super.shellApi.adManager).trackCampaign("CostumizedFromNPC", skinPart.id, skinPart.value.substr(AdvertisingConstants.AD_PATH_KEYWORD.length+1));
			}
		}
		*/
		
		override public function loaded():void
		{
			loadLoginButton();
		}
		
		/**** login setup ****/
		private function loadLoginButton():void
		{
			if(super.shellApi.networkAvailable())
			{
				super.loadFileDeluxe("ui/login/getLookButton.swf", true, true, setupLoginButton);
			}
		}
		
		private function setupLoginButton(clip:MovieClip):void
		{
			super.pinToEdge(clip, DisplayPositions.RIGHT_CENTER);
			super.groupContainer.addChild(clip);
			ButtonCreator.createButtonEntity(clip, this, displayLogin, null, null, null, true, true);
			
			super.loaded();
		}
		
		private function displayLogin(button:Entity):void
		{
			if(super.getGroupById(LoginPanel.GROUP_ID, this) == null)
			{
				var group:LoginPanel = new LoginPanel(super.groupContainer) as LoginPanel;
				group.loggedIn.add(handleLogin);
				super.addChildGroup(group);
			}
		}
		
		private function handleLogin(loginData:LoginData):void
		{
			var lookConverter:LookConverter = new LookConverter();
			var lookData:LookData = lookConverter.lookDataFromLookString(loginData.look);
			//SkinUtils.applyLook(_player, lookData, true);
			
			//this.firstName = loginData.firstName;
			//this.lastName = loginData.lastName;
			//this.textField.text = this.firstName + " " + this.lastName;
			
			loginClose();
		}
		
		private function loginClose():void
		{
			var group:LoginPanel = super.getGroupById(LoginPanel.GROUP_ID, this) as LoginPanel;
			
			if(group)
			{
				super.removeGroup(group, true);
			}
		}
		/********/
	}
}
