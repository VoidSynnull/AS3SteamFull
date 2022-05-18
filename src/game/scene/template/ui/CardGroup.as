package game.scene.template.ui
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.character.Character;	
	import game.components.entity.character.Skin;
	import game.components.ui.Button;
	import game.components.ui.CardItem;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.CardItemCreator;
	import game.data.ConditionalData;
	import game.data.ParamData;
	import game.data.ads.AdvertisingConstants;
	import game.data.character.LookAspectData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.display.AssetData;
	import game.data.print.PrintAvatarPoster;
	import game.data.profile.TribeData;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.text.TextData;
	import game.data.text.TextStyleData;
	import game.data.ui.card.CardAction;
	import game.data.ui.card.CardButtonData;
	import game.data.ui.card.CardItemData;
	import game.data.ui.card.CardRadioButtonData;
	import game.managers.ItemManager;
	import game.nodes.entity.character.NpcNode;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scene.template.SceneUIGroup;
	import game.ui.card.CardView;
	import game.ui.elements.MultiStateToggleButton;
	import game.ui.hud.Hud;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.ColorUtil;
	import game.util.DataUtils;
	import game.util.DisplayPositions;
	import game.util.DisplayUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TribeUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Group to handle creation of cards, which are their own groups.
	 * CardGroup must be a child of a DisplayGroup. 
	 * @author umckiba
	 * 
	 */
	public class CardGroup extends Group
	{
		public function CardGroup()
		{
			super();
			super.id = GROUP_ID;
			_cardCreator = new CardItemCreator();
			cardActivated = new Signal();
		}
		
		override public function destroy():void
		{			
			_cardCreator = null;
			cardActivated.removeAll();
			cardActivated = null;
			super.destroy();
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////// CREATE CARDVIEW ///////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Create basic UIView containing card Entity without card data applied.
		 */
		public function createCardView( group:DisplayGroup ):CardView
		{
			return group.addChildGroup( new CardView() ) as CardView;
		}
		
		/**
		 * Create a new UIView for a card from path to card xml.
		 */
		public function createCardViewByItem( group:DisplayGroup, container:DisplayObjectContainer, itemId:String, setId:String, cardView:CardView = null, handler:Function = null, loadBase:Boolean=true, loadCardContent:Boolean=true ):CardView
		{
			if(cardView == null)
				cardView = createCardView( group );
			var cardItem:CardItem;
			if( loadCardContent )	// if loading special content 
			{
				cardItem = createCardItem( itemId, setId, loadBase, Command.create( completeCardView, cardView, handler ) );
			}
			else
			{
				cardItem = createCardItem( itemId, setId, loadBase, handler );
			}
			cardView.createCardEntity(cardItem, container);
			
			return cardView;
		}
		
		private function completeCardView( cardItem:CardItem, cardView:CardView, handler:Function = null ):void
		{
			cardView.loadCardContent( handler );
		}
		
		/**
		 * Handler added to each button's click dispatch.
		 */
		private function onCardButtonClicked( entity:Entity, cardItem:CardItem, actions:Vector.<CardAction> ):void
		{
			// TODO :: would like to be able to call action methods after inventory has closed - Bard
			
			//track card use if not campaign card
			if( !DataUtils.validString(cardItem.cardData.campaignId) )
			{
				trace("CardGroup :: track : event: " + CARD_USED + ", choice: " + cardItem.cardData.type + ", subchoice: " + cardItem.cardData.id);
				super.shellApi.track( CARD_USED, cardItem.cardData.type, cardItem.cardData.id );
			}
			//	else
			//	{
			//		trace("CardGroup :: track : campaign " + cardItem.cardData.campaignId + ", event: " + CARD_USED + ", choice: " + cardItem.cardData.type + ", subchoice: " + cardItem.cardData.id);
			//		super.shellApi.track( CARD_USED, cardItem.cardData.type, cardItem.cardData.id, cardItem.cardData.campaignId);
			//	}
			
			_blockParentClose = false;	// reset card activation flag
			if( actions )
			{
				var action:CardAction;
				for (var i:int = 0; i < actions.length; i++) 
				{
					action = actions[i];
					
					if(action.blockInventoryClose)
						_blockParentClose = true;
					
					handleAction( cardItem, action );
				}
			}
			cardItem.buttonPress.dispatch();
			
			//if( !_blockParentClose )	// TEMP :: Until I fix Tweening for groups, _isSceneLoad blocks Inventory from closing. - Bard
			//{
				cardActivated.dispatch( actions, _blockParentClose ); 
			//}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////// CARD ITEM DATA ////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Creates a CardItem component, and loads the card xml that defines it.
		 * If loadDisplay is true, process to creates card's display will continue once card data xml is loaded.
		 * 
		 * @param itemId - card id (unique within set)
		 * @param setId - id for set that card exists within (e.g. store, custom, carrot)
		 * @param loadDisplay - flag determining if card display should be created once card data is complete
		 * @param handler - called once card data is complete
		 * @return 
		 */
		public function createCardItem( itemId:String, setId:String, loadDisplay:Boolean=true, handler:Function = null ):CardItem
		{
			var cardItem:CardItem = new CardItem();
			cardItem.itemId = itemId;
			if (setId == CardGroup.CUSTOM)
			{
				cardItem.pathPrefix = "items/" + AdvertisingConstants.AD_PATH_KEYWORD + "/" + itemId;
			}
			else
			{
				cardItem.pathPrefix = "items/" + setId + "/" + itemId;
			}
			loadCardItem( cardItem, loadDisplay, handler );
			return cardItem;
		}
		
		/**
		 * Load initial xml for card.
		 * If isPreloadDisplay is set to true, card loading will continue until completion.
		 * @param cardItem
		 * @param isPreloadDisplay
		 * @param handler
		 */
		public function loadCardItem( cardItem:CardItem, loadDisplay:Boolean, handler:Function = null):void
		{
			if( !cardItem.isLoading )
			{
				cardItem.isLoading = true;
				super.shellApi.loadFile( super.shellApi.dataPrefix + cardItem.pathPrefix + ".xml", onCardDataXmlLoaded, cardItem, loadDisplay, handler );	// load card xml				
				trace( "CardGroup :: loadCardItem : " +  super.shellApi.dataPrefix + cardItem.pathPrefix + ".xml");
			}
		}
		
		/**
		 * Callback for card xml loaded.  
		 * @param cardXml
		 * @param cardItem
		 * @param isPreloadDisplay
		 * @param handler
		 */
		public function onCardDataXmlLoaded( cardXml:XML, cardItem:CardItem, loadDisplay:Boolean, handler:Function = null):void
		{
			try 
			{
				if ( cardXml != null )
				{
					if( cardItem.cardData == null )
					{
						cardItem.cardData = new CardItemData(null, shellApi);
					}
					
					cardItem.cardData.parse( cardXml );
					
					onCardDataLoaded( cardItem, loadDisplay, handler);
				}
				else
				{
					var message:String = (" CardGroup :: Card XML not found.");
					handler( cardItem );
				}
			}
			catch ( e:Error )
			{
				trace( "Error :: CardGroup : " + e );
				if( handler != null )
				{
					handler( cardItem );
				}
				//handle whatever needs handling
			}
		}
		
		/**
		 * CardData is available, if isPreloadDisplay is true assets will begin loading.
		 * @param cardItem
		 * @param isPreloadDisplay
		 * @param handler
		 */
		protected function onCardDataLoaded( cardItem:CardItem, loadDisplay:Boolean, handler:Function = null):void
		{
			trace("CardGroup :: onCardDataLoaded - loadDisplay? " + loadDisplay);
			if( loadDisplay )
			{
				loadCardBase( cardItem, handler);
			}
			else
			{
				if( handler != null )
				{
					handler( cardItem );
				}
			}
		}
		
		/**
		 * Load the card display, but do not add to display heirarchy
		 */
		private function loadCardBase( cardItem:CardItem, handler:Function = null):void
		{
			if( cardItem )
			{
				if( cardItem.cardData )
				{
					// create/clear spriteHolder, this holds display until it is ready to be applied 
					cardItem.resetSpriteHolder();
					
					// dispatches when complete with all loading
					if( handler != null )
					{
						cardItem.loadComplete.add( Command.create( handler, cardItem ) );
					}
					
					// RLH: some conditionals such as determineHasLook() expect cardItem.value to already be present
					// but note than any cardItem.value based on conditionals won't happen until checkValue() below
					if (cardItem.cardData.value)
						cardItem.value = cardItem.cardData.value;
					
					// determine conditionals
					determineConditionals( cardItem );
					
					// check for value -- NOTE: must call after determineConditionals()
					checkValue( cardItem );
					
					// load assets
					cardItem.currentElement = 0;
					loadAssets( cardItem);
				}
			}
		}
		
		/**
		 * Called when CardItem has finished loading
		 */
		protected function cardItemLoaded( cardItem:CardItem ):void
		{			
			cardItem.displayLoaded = true;
			cardItem.isLoading = false;
			cardItem.loadComplete.dispatch();
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////// CARD VALUE //////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Load the card display, but do not add to display heirarchy
		 */
		private function checkValue( cardItem:CardItem ):void
		{
			if( cardItem.cardData.value != null )
			{
				if( cardItem.cardData.value is ConditionalData )
				{
					cardItem.value = ConditionalData(cardItem.cardData.value).value;
				}
				else
				{
					cardItem.value = cardItem.cardData.value;
				}
			}
			else	// if value not define, set ot default of "0"
			{
				//Drew - Why are we doing this? It's potentially breaking value checking.
				//cardItem.value = "0";
			}
		}
		
		public function updateValue( cardItem:CardItem, value:* ):void
		{
			if( cardItem.value != value )
			{
				cardItem.value = value;	// TODO :: check to see if this has even changed before processing? - Bard
				
				// reset conditionals now that value has been changed
				determineConditionals( cardItem );
				
				// update buttons ( currently just changes visibility based on conditionals )
				var buttonData:CardButtonData;
				for (var i:int = 0; i < cardItem.cardData.buttonData.length; i++) 
				{
					buttonData = cardItem.cardData.buttonData[i];
					if( buttonData.entity )							// check to see that a button has been made, otherwise there is nothing to update
					{
						if( buttonData.conditional )				// check conditional was defined 
						{
							if( !checkCondition( cardItem.cardData, buttonData.conditional ) )	// if conditional not met, hide button
							{
								buttonData.entity.get(Display).visible = false;
							}
							else
							{
								buttonData.entity.get(Display).visible = true;
							}
						}
					}
				}
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////// CONDITIONALS //////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function determineConditionals( cardItem:CardItem ):void
		{
			if( cardItem.cardData.conditionals )
			{
				for (var i:int = 0; i < cardItem.cardData.conditionals.length; i++) 
				{
					determineConditional( cardItem, cardItem.cardData.conditionals[i] );
				}
			}
		}
		
		/**
		 * Check conditional against currently defined conditionals.
		 */
		private function checkCondition( cardData:CardItemData, conditional:ConditionalData ):Boolean
		{
			if( cardData.conditionals )
			{
				var determinedCondtional:ConditionalData;
				for (var i:int = 0; i < cardData.conditionals.length; i++) 
				{
					determinedCondtional = cardData.conditionals[i];
					if( conditional.id == determinedCondtional.id )
					{
						return ( determinedCondtional.isTrue == conditional.isTrue );
					}
				}
			}
			return false;
		}
		
		private function determineConditional( cardItem:CardItem, conditional:ConditionalData ):void
		{
			switch( conditional.type )
			{
				case ConditionalData.HAS_ABILITY:
				{
					determineHasAbility( cardItem, conditional );
					break;
				}	
				case ConditionalData.IN_ISLAND:
				{
					determineInIsland( conditional );
					break;
				}
				case ConditionalData.IN_SCENE:
				{
					determineInScene( conditional );
					break;
				}
				case ConditionalData.HAS_PART:
				{
					determineHasPart( conditional );
					break;
				}	
				case ConditionalData.HAS_LOOK:
				{
					determineHasLook( cardItem, conditional );
					break;
				}	
				case ConditionalData.HAS_PET_LOOK:
				{
					determineHasLook( cardItem, conditional, true );
					break;
				}	
				case ConditionalData.CHECK_EVENTS:
				{
					determineCheckEvents( cardItem.cardData, conditional );
					break;
				}	
				case ConditionalData.CHECK_TRIBE:
				{
					determineCheckTribe( cardItem.cardData, conditional );
					break;
				}
				case ConditionalData.CHECK_USER_FIELD:
				{	
					determineCheckUserField(cardItem.cardData, conditional);
					break;
				}
				case ConditionalData.CHECK_IF_MOBILE:
				{	
					determineIfMobile(cardItem.cardData, conditional);
					break;
				}
				case ConditionalData.CHECK_GENDER:
				{	
					checkGender(cardItem.cardData, conditional);
					break;
				}
				case ConditionalData.USED_ITEM:
				{	
					checkIfUsedItem(cardItem.cardData, conditional);
					break;
				}
				case ConditionalData.IS_SCALED:
				{	
					checkScaled(cardItem.cardData, conditional, true);
					break;
				}
				case ConditionalData.ALL_SCALED:
				{	
					checkScaled(cardItem.cardData, conditional, false);
					break;
				}
				case ConditionalData.CHECK_LANGUAGE:
				{	
					checkLanguage(cardItem.cardData, conditional);
					break;
				}
				default:
				{
					break;
				}
			}
		}
		
		private function checkLanguage(cardData:CardItemData, conditional:ConditionalData):void
		{
			var language:int = 0;// default to english
			if( conditional.paramList )	// TODO :: want to switch this to retrieving by id
			{
				language = int( conditional.paramList.byIndex(0) );
			}
			
			if( language == shellApi.profileManager.active.preferredLanguage)
			{
				conditional.isTrue = true;
			}
			else
			{
				conditional.isTrue = false;
			}
		}
		
		private function checkGender(cardData:CardItemData, conditional:ConditionalData):void
		{
			var playerLook:LookData = SkinUtils.getLook(this.shellApi.player, true);
			if( playerLook == null ) { playerLook = new LookConverter().lookDataFromPlayerLook(super.shellApi.profileManager.active.look); }
			conditional.value = playerLook.getValue(SkinUtils.GENDER);	
		}
		
		private function checkIfUsedItem(cardData:CardItemData, conditional:ConditionalData):void
		{
			conditional.isTrue = shellApi.checkItemUsedUp(conditional.paramList.params[0].value);
		}
		
		private function determineHasAbility( cardItem:CardItem, conditional:ConditionalData ):void
		{
			if (cardItem.cardData.specialIds)
			{
				var abilityId:String = cardItem.value;
				// no value so we need to see if we can  find one
				if( !abilityId)
				{
					// if there is an array of specials then just take the first id
					if(cardItem.cardData.specialIds)
					{
						abilityId = cardItem.cardData.specialIds[0];
					}
					else
					{
						abilityId = "";
						trace("CardGroup :: Could not find a special ability to determine has ability.");
					}
				}
				
				conditional.isTrue = CharUtils.hasSpecialAbility( super.shellApi.player, abilityId );
			}
		}
		
		private function determineInIsland( conditional:ConditionalData ):void
		{
			var currentIsland:String = super.shellApi.island			
			var requiredIsland:String = DataUtils.getString( conditional.paramList.byIndex(0) ); 
			if ( currentIsland == requiredIsland )
			{
				conditional.isTrue = true;
				return;
			}
			conditional.isTrue = false;
		}
		
		private function determineInScene( conditional:ConditionalData ):void
		{
			var currentScene:Class = ClassUtils.getClassByObject( shellApi.sceneManager.currentScene );
			
			var scenes:Array = DataUtils.getArray( conditional.paramList.byIndex(0) ); 
			for (var i:int = 0; i < scenes.length; i++) 
			{
				if( currentScene == ( ClassUtils.getClassByName( scenes[i] ) ) )
				{
					conditional.isTrue = true;
					return;
				}
			}
			conditional.isTrue = false;
		}
		
		private function determineHasPart( conditional:ConditionalData ):void
		{
			var playerLook:LookData = SkinUtils.getLook(this.shellApi.player, false);
			if( playerLook == null ) 
			{ 
				playerLook = new LookConverter().lookDataFromPlayerLook(super.shellApi.profileManager.active.look); 
			}
			
			var skinId:String = conditional.paramList.byIndex(0); 
			
			var playersSkinValue:String = playerLook.getValue(skinId);
			
			var skinValue:String;
			
			for (var i:int = 1; i < conditional.paramList.length; i++) 
			{
				skinValue = DataUtils.getString(conditional.paramList.byIndex(i));
				if( playersSkinValue == skinValue )
				{
					conditional.isTrue = true;
					return;
				}
			}
			
			conditional.isTrue = false
		}
		
		/**
		 * Determine if player has look(s) indicated in card xml (expanded by Rick Hocker)
		 * To check against multiple looks, use a value of "anyLook" in the xml
		 * @param cardItem
		 * @param conditional
		 */
		private function determineHasLook( cardItem:CardItem, conditional:ConditionalData, isPet:Boolean = false ):void
		{
			// vector for looks
			var looks:Vector.<LookData> = new Vector.<LookData>();
			// if card data has looks
			if( cardItem.cardData.looks )
			{
				// if checking for "anyLook", then set vector to all looks in card data
				if (cardItem.value == "anyLook")
				{
					looks = cardItem.cardData.looks;
				}
				else
				{
					// if checking one look, then add look based on value (if value is undefined, then retrieve look at index 0)
					looks.push(cardItem.cardData.getLook(cardItem.value));
				}
			}
			
			// if vector is not empty
			if( looks.length != 0 )
			{
				// get player look
				var playerLook:LookData;
				if (isPet)
				{
					var data:SpecialAbilityData = shellApi.specialAbilityManager.getAbility("pets/pop_follower");
					if (data != null)
					{
						playerLook = data.specialAbility.getLook();
					}
					else
					{
						trace("Error: No pet look found!");
						// if no pet look, then force conditional to false
						conditional.isTrue = false;
						return;
					}
				}
				else
				{
					playerLook = SkinUtils.getLook(this.shellApi.player, true);
					// if player look is null, then pull from profile
					if ( playerLook == null )
					{
						playerLook = new LookConverter().lookDataFromPlayerLook(super.shellApi.profileManager.active.look);
					}
				}
				
				// number of looks that match
				var matches:int = 0;
				// check each look
				for each (var lookData:LookData in looks)
				{
					var isMatch:Boolean = true;
					// check each look aspect
					for each ( var lookAspect:LookAspectData in lookData.lookAspects ) 
					{
						// if look aspects don't match, then set to no match and break
						if( playerLook.getValue(lookAspect.id) != lookAspect.value )
						{
							isMatch = false;
							break;
						}
					}
					// if all look aspects match, then increment matches
					if (isMatch)
						matches++;
				}
				// if one look, then set conditional based on match
				if (looks.length == 1)
				{
					conditional.isTrue = isMatch;
				}
				else
				{
					// if multiple looks, then set conditional based on whether there are any matches or not
					conditional.isTrue = (matches != 0);
				}
			}
			else
			{
				// if empty vector, then set conditional to false
				conditional.isTrue = false;
			}
		}
		
		private function determineCheckEvents( cardData:CardItemData, conditional:ConditionalData ):void
		{
			var event:String;
			var value:String;
			
			if( conditional.paramList )	// TODO :: want to switch this to retrieving by id
			{
				event = String( conditional.paramList.byIndex(0) );
			}
			
			if( super.shellApi.gameEventManager.check( event, cardData.subType ))
			{
				conditional.isTrue = true;
				value = conditional.paramList.byId( "true" );
				if( DataUtils.validString( value ))
				{
					cardData.value = value;
				}
			}
			else
			{
				conditional.isTrue = false;
				value = conditional.paramList.byId( "false" );
				if( DataUtils.validString( value ))
				{
					cardData.value = value;
				}
			}
		}
		
		/**
		 * Checks local userfields.
		 * Does not perform an external query for userfield, the userfield must already be stored locally 
		 * @param cardData
		 * @param conditional
		 */
		private function determineCheckUserField(cardData:CardItemData, conditional:ConditionalData):void
		{
			var islandName:String = DataUtils.useString(conditional.paramList.byId(ISLAND), super.shellApi.island);
			if( islandName == NONE ) { islandName = ""; }	// when referencing universal userfields not island specific use "none" as island value
			var fieldName:String = DataUtils.getString(conditional.paramList.byId(USERFIELD));
			var userField:* = shellApi.getUserField(fieldName, islandName);

			// TODO :: Need more checking on validiy of userfield
			// if Array use length of Array as value. Note : Not ideal really, necessary fro how shards are being managed in home scene. - bard
			if( userField is Array )
			{
				userField = (userField as Array).length;
			}
			conditional.value = userField;
		}
		
		private function determineIfMobile(cardData:CardItemData, conditional:ConditionalData):void
		{
			if( PlatformUtils.isMobileOS)
			{
				conditional.isTrue = true;
			}
			else
			{
				conditional.isTrue = false;
			}
		}
		
		private function determineCheckTribe( cardData:CardItemData, conditional:ConditionalData ):void
		{
			var tribeData:TribeData = TribeUtils.getTribeOfPlayer( super.shellApi );
			if( tribeData )
			{
				conditional.value = tribeData.id;
			}
			else
			{
				trace( "Error :: CardGroup :: tribe value not found for player, being set to default");
				conditional.value = TribeUtils.getTribeDataByIndex(0).id;
			}
		}
		
		private function checkScaled(cardData:CardItemData, conditional:ConditionalData, isAvatar:Boolean):void
		{
			if (isAvatar && shellApi.player != null)
			{
				conditional.isTrue = this.shellApi.player.get(Spatial).scaleY != 0.36;
			}
			else
			{
				// check all npcs
				var isScaled:Boolean = true;
				var entityArray:Vector.<Entity> = CharacterGroup(this.shellApi.sceneManager.currentScene.getGroupById("characterGroup")).getNPCs("NPCS");
				// for each NPC
				for each (var char:Entity in entityArray)
				{
					// if any NPC is at normal scale then set flag to false
					if (char.get(Spatial).scaleY == 0.36)
					{
						isScaled = false;
						break;
					}
				}
				conditional.isTrue = isScaled;
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////// BUTTON ACTIONS ////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Handles actions associated with card buttons.
		 */
		protected function handleAction( cardItem:CardItem, cardAction:CardAction ):void
		{
			// check for conditionals
			if( cardAction.conditional )
			{
				if( !checkCondition( cardItem.cardData, cardAction.conditional ) )
				{
					return;
				}
			}
			switch(cardAction.type)
			{
				case cardAction.TRACK:
				{
					track( cardItem, cardAction );
					break;
				}
				case cardAction.TRIGGER_EVENT:
				{
					triggerEvent( cardItem, cardAction );
					break;
				}
				case cardAction.REMOVE_EVENT:
				{
					removeEvent( cardItem, cardAction );
					break;
				}
				case cardAction.OPEN_POPUP:
				case cardAction.OPEN_VIDEO_POPUP:	// NOTE :: This action is redundant, would like to phase out
				{
					openPopup( cardItem, cardAction );
					break;
				}
				case cardAction.LOAD_SCENE:
				{
					openScene( cardItem, cardAction );
					break;
				}
				case cardAction.COSTUMIZE:
				{
					costumize( cardItem, cardAction );
					break;
				}
				case cardAction.APPLY_LOOK:
				{
					applyLook( cardItem, cardAction );
					break;
				}
				case cardAction.APPLY_LOOK_NPC:
				{
					applyLookNPC( cardItem, cardAction );
					break;
				}
				case cardAction.REMOVE_LOOK:
				{
					removeLook( cardItem, cardAction );
					break;
				}
				case cardAction.ACTIVATE_POWER:
				{
					activatePower( cardItem, cardAction );
					break;
				}
				case cardAction.DEACTIVATE_POWER:
				{
					deactivatePower( cardItem, cardAction );
					break;
				}
				case cardAction.ADD_GROUP:
				{
					addGroup( cardItem, cardAction );
					break;
				}
				case cardAction.REMOVE_ITEM:
				{
					removeItem( cardItem, cardAction );
					break;
				}
				case cardAction.GET_ITEM:
				{
					getItem( cardItem, cardAction );
					break;
				}
				case cardAction.SHOW_ITEM:
				{
					showItem( cardItem, cardAction );
					break;
				}
				case cardAction.SET_USER_FIELD:
				{
					setUserField( cardItem, cardAction );
					break;
				}
				case cardAction.PRINT_POSTER:
				{
					printPoster( cardItem, cardAction );
					break;
				}
				case cardAction.PLAY_SOUND:
				{
					playAudio( cardItem, cardAction );
					break;
				}
				case cardAction.SHRINK_PLAYER:
				{
					doShrink( cardItem, cardAction, true, true);
					break;
				}
				case cardAction.SHRINK_NPCS:
				{
					doShrink( cardItem, cardAction, true, false);
					break;
				}
				case cardAction.UNSHRINK_PLAYER:
				{
					doShrink( cardItem, cardAction, false, true);
					break;
				}
				case cardAction.UNSHRINK_NPCS:
				{
					doShrink( cardItem, cardAction, false, false);
					break;
				}
				default:
				{
					trace("CardGroup : handleAction : action type not found: " + cardAction.type);
					break;
				}
			}
		}
		
		private function removeEvent(cardItem:CardItem, cardAction:CardAction):void
		{
			var event:String = String( cardAction.params.byId( EVENT ) );
			if( !DataUtils.validString(event) )
			{
				event = String( cardAction.params.byIndex( 0 ) );
				if( !DataUtils.validString(event) )
				{
					event = cardItem.value;
				}
			}
			
			shellApi.removeEvent(event);
		}
		
		protected function track( cardItem:CardItem, cardAction:CardAction, event:String = null ):void
		{
			var eventType:String = cardAction.params.byId( CardGroup.EVENT_TYPE );
			if (event != null) { eventType = event; }
			var choice:String = DataUtils.useString( cardAction.params.byId( CardGroup.EVENT_CHOICE ), "" );
			var subchoice:String = DataUtils.useString( cardAction.params.byId( CardGroup.EVENT_SUBCHOICE ), "" );
			var campaignId:String = cardItem.cardData.campaignId;
			
			// if campaign card, then route through ad manager
			if ((campaignId) && (cardItem.cardData.type == "custom"))
			{
				super.shellApi.adManager.track(campaignId, eventType, choice, subchoice);
			}
			else
			{
				// if not campaign card, use standard tracking
				trace("CardGroup :: track : event: "+eventType+", choice: "+choice+", subchoice: "+subchoice+", campaign: "+campaignId );
				super.shellApi.track( eventType, choice, subchoice, campaignId);
			}
		}
		
		/**
		 * Triggers a scene event.
		 * Event is checked for in the CardAction's parameters, if not found the CardItem's value is used.
		 * @param cardItem
		 * @param cardAction
		 * 
		 */
		private function triggerEvent( cardItem:CardItem, cardAction:CardAction ):void
		{
			var event:String = String( cardAction.params.byId( EVENT ) );
			if( !DataUtils.validString(event) )
			{
				event = String( cardAction.params.byIndex( 0 ) );
				if( !DataUtils.validString(event) )
				{
					event = cardItem.value;
				}
			}
			
			// assume we don't save the event
			var save:Boolean = false;
			if( cardAction.params.byIndex( 1 ) != null )
			{
				save = DataUtils.getBoolean(cardAction.params.byIndex( 1 ));
			}
			
			super.shellApi.triggerEvent( event, save );
			//super.shellApi.completeEvent(item.eventArgs[0], item.eventArgs[1]);
		}
		
		private function removeItem( cardItem:CardItem, cardAction:CardAction ):void
		{
			var item:String = String( cardAction.params.byId( ITEM ));
			if( !DataUtils.validString( item ))
			{
				item = String( cardAction.params.byIndex( 0 ) );
			}
			
			super.shellApi.removeItem( item );
		}
		
		private function getItem( cardItem:CardItem, cardAction:CardAction ):void
		{
			var item:String = String( cardAction.params.byId( ITEM ));
			
			if( !DataUtils.validString(item) )
			{
				item = String( cardAction.params.byIndex( 0 ) );
			}
			
			// assume show parameter
			var show:Boolean = true;
			if( cardAction.params.byIndex( 1 ) != null )
			{
				show = DataUtils.getBoolean(cardAction.params.byIndex( 1 ));
			}
			
			super.shellApi.getItem( item, null, show );
		}
		
		private function showItem( cardItem:CardItem, cardAction:CardAction ):void
		{
			var item:String = String( cardAction.params.byId( ITEM ));
			
			if( !DataUtils.validString(item) )
			{
				item = String( cardAction.params.byIndex( 0 ) );
			}
		
			var itemGroup:ItemGroup = super.shellApi.currentScene.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( itemGroup )
			{
				itemGroup.showItem( item );	// TODO :: this assumes island cards, might need another parameter for custom/limited or store. - Bard
			}
			else
			{
				trace("Error :: CardGroup : showItem : ItemGroup has not been added to current scene.")
			}
		}
		
		private function costumize( cardItem:CardItem, cardAction:CardAction ):void
		{
			var lookData:LookData = cardItem.cardData.getLook( cardItem.value );
			var uiGroup:SceneUIGroup = super.parent.getGroupById( SceneUIGroup.GROUP_ID ) as SceneUIGroup;
			
			var petObj:Object = {"pet":false};
			// check for active pet and if pet action
			if (checkForActivePet(uiGroup, cardAction, petObj))
			{
				// will open costumizer & close inventory
				uiGroup.hud.openCostumizer( lookData, true, false, null, petObj["pet"] );
			}
		}
		
		// check if pet action and return false if pet action and no pet is active
		private function checkForActivePet(uiGroup:SceneUIGroup, cardAction:CardAction, petObj:Object):Boolean
		{
			if (uiGroup == null)
			{
				uiGroup = super.parent.getGroupById( SceneUIGroup.GROUP_ID ) as SceneUIGroup;
			}
			
			// check for pet param
			if ((cardAction.params != null) && (cardAction.params.getParamId("pet")))
			{
				var petParam:ParamData = cardAction.params.getParamId("pet");
				petObj["pet"] = DataUtils.getBoolean(petParam.value);
				
				// if no pet follower active, then show alert
				var data:SpecialAbilityData = shellApi.specialAbilityManager.getAbility("pets/pop_follower");
				if (data == null)
				{
					uiGroup.askForConfirmation(SceneUIGroup.MUST_HAVE_PET, uiGroup.removeConfirm, uiGroup.removeConfirm);
					return false;
				}
			}
			return true;
		}

		private function openPopup( cardItem:CardItem, cardAction:CardAction ):void
		{
			// get class by id, if that fails just get first index
			var className:String = String( cardAction.params.byId( CLASS_NAME ) );
			if( DataUtils.validString( className ) )
			{
				var popupClass:Class = ClassUtils.getClassByName( className );
				if( !popupClass )
				{
					trace( "Error :: CardGroup : " + className + " is not a valid class name." );
					popupClass = ClassUtils.getClassByName(cardAction.params.byIndex( 0 ));
				}
			}else{
				trace( "Error :: CardGroup : " + className + " is not a valid class name." );
			}
			
			//var popup:Popup = super.parent.parent.addChildGroup(new popupClass()) as Popup;
			var popup:Popup = super.shellApi.sceneManager.currentScene.addChildGroup(new popupClass()) as Popup;
			// NOTE :: Popup MUST have an init function that can handle 
			popup.setParams(cardAction.params);
			
			// transfer hud reset & scene unpause to current popup ( if hud has a popup open, say selecting a card from the Inventory )
			var hud:Hud = super.getGroupById( Hud.GROUP_ID ) as Hud;
			if( hud )
			{
				hud.popupTransfer( popup );
			}
			
			// if card has campaign data pass along to popup
			popup.campaignData = cardItem.cardData.campaignData;
			// set clickURL to game click url in param list of click URLs
			if(popup.campaignData)
			{
				popup.campaignData.clickUrls = cardItem.cardData.campaignData.clickUrls;
				// add game ID if any
				var gameID:String = String( cardAction.params.byId( "gameID" ) );
				if (gameID)
					popup.campaignData.gameID = gameID;
				// add game class if any
				var gameClass:String = String( cardAction.params.byId( "gameClass" ) );
				if (gameClass)
					popup.campaignData.gameClass = gameClass;
			}
			
			popup.init( super.shellApi.sceneManager.currentScene.overlayContainer );
		}
		
		private function openScene( cardItem:CardItem, cardAction:CardAction ):void
		{
			var sceneClass:Class = ClassUtils.getClassByName( cardAction.params.byId( CLASS_NAME ) );
			if( !sceneClass )
			{
				sceneClass = ClassUtils.getClassByName(cardAction.params.byIndex(0));
			}
			var arcadeGame:String = String( cardAction.params.byId( "arcadeGame" ) );
			if(arcadeGame)
				shellApi.arcadeGame = arcadeGame;
			super.shellApi.loadScene( sceneClass );
			_blockParentClose = true;		// TEMP :: Until I fix Tweening for groups
		}
		
		private function addGroup( cardItem:CardItem, cardAction:CardAction ):void
		{
			// get class by  id, if that fails just get first index
			var classParam:ParamData = cardAction.params.getParamId( CLASS_NAME );
			if( !classParam )
			{
				classParam = cardAction.params.getParamByIndex(0);
			}
			
			if( classParam )
			{
				var groupClass:Class = ClassUtils.getClassByName(classParam.value);
				var group:Group = super.parent.parent.addChildGroup(new groupClass());
				
				// params can be passed through an init function if one has been specified, assumes first param is the class
				if( group["init"] )
				{
					cardAction.params.removeParam( classParam );
					(group["init"] as Function).apply(null, cardAction.params.convertToArray() );
				}
			}
		}

		private function applyLook( cardItem:CardItem, cardAction:CardAction ):void
		{
			var isPermanent:Boolean = true;
			var newLook:String;
			var lookData:LookData;
			
			var petObj:Object = {"pet":false};
			// check for active pet and if pet action
			if (checkForActivePet(null, cardAction, petObj))
			{
				if( cardAction.params )
				{
					if( cardAction.params.length > 0 )
					{
						isPermanent = DataUtils.getBoolean(cardAction.params.byId( "perm" ));
						newLook = getParamValue( "useLook", cardItem.cardData, cardAction );
					}
				}
				
				lookData = ( newLook ) ? cardItem.cardData.getLook( newLook ) : cardItem.cardData.getLook( cardItem.value );
				if( lookData == null )
				{
					lookData = cardItem.cardData.getLook();
				}
				
				if (petObj["pet"])
				{
					// apply look to pet
					var data:SpecialAbilityData = shellApi.specialAbilityManager.getAbility("pets/pop_follower");
					if (data != null)
					{
						// get current look
						var currentLookData:LookData = data.specialAbility.getLook();
						// iterate through parts
						var ids:Array = [SkinUtils.SKIN_COLOR, SkinUtils.FACIAL, SkinUtils.EYES, SkinUtils.OVERBODY, SkinUtils.HAT, SkinUtils.MARKS, SkinUtils.MOUTH];
						for each (var id:String in ids)
						{
							// get current aspect
							var lookAspect:LookAspectData = currentLookData.getAspect(id);
							// new look aspect
							var newLookAspect:LookAspectData = lookData.getAspect(id);
							// if found in current and not in new look, then add to new look
							if ((lookAspect != null) && (newLookAspect == null))
							{
								lookData.applyAspect(lookAspect);
							}
							// if new look has data, then track new part to be applied
							else if (newLookAspect != null)
							{
								shellApi.track("ApplyLook", id, String(newLookAspect.value), "pets");
							}
						}
						data.specialAbility.setLook(lookData);
					}
				}
				else
				{
					// TODO :: Need to debug these changes
					if( this.shellApi.player.has(Skin) )	// apply to player skin
					{
						SkinUtils.applyLook( super.shellApi.player, lookData, isPermanent );
						if(isPermanent)
						{
							super.shellApi.saveLook();
							//super.shellApi.siteProxy.saveLook();
							//super.shellApi.profileManager.save();	// NOTE :: Any reason we aren't using this instead
						}
					}
					else									// apply directly to active look, if player does not have skin
					{ 
						var lookConverter:LookConverter = new LookConverter();
						var playerLook:LookData = lookConverter.lookDataFromPlayerLook(super.shellApi.profileManager.active.look); 
						playerLook.merge(lookData);
						super.shellApi.profileManager.active.look = lookConverter.playerLookFromLookData(playerLook);
						if(isPermanent)
						{
							super.shellApi.saveLook(playerLook);
							//super.shellApi.siteProxy.saveLook(null,playerLook);
							//super.shellApi.profileManager.save();	// NOTE :: Any reason we aren't using this instead
						}
					}
				}
			}
		}
		
		private function applyLookNPC( cardItem:CardItem, cardAction:CardAction ):void
		{	
			var lookData:LookData = cardItem.cardData.getLook( String(cardItem.value) );
			
			// Loop across NPC nodes and apply the look to the entity
			var nodeList:NodeList = super.systemManager.getNodeList( NpcNode );
			for( var node : NpcNode = nodeList.head; node; node = node.next )
			{
				var npcEntity:Entity = node.entity;
				
				// skip mannequins
				if ((npcEntity.has(Character)) && (npcEntity.get(Character).variant == CharacterCreator.VARIANT_MANNEQUIN))
					continue;
					
				// don't apply to followers
				if ((npcEntity.has(Id)) && (npcEntity.get(Id).id.indexOf("popFollower") != 0))
				{
					SkinUtils.applyLook( node.entity, lookData );
				}
			}
		}
		
		private function removeLook( cardItem:CardItem, cardAction:CardAction ):void
		{
			var petObj:Object = {"pet":false};
			// check for active pet and if pet action
			if (checkForActivePet(null, cardAction, petObj))
			{
				var isPermanent:Boolean = true;
				var newLook:String;
				var lookData:LookData;
	
				if( cardAction.params )
				{
					if( cardAction.params.length > 0 )
					{
						isPermanent = DataUtils.getBoolean(cardAction.params.byIndex(0));
						newLook = getParamValue( "useLook", cardItem.cardData, cardAction );
					}
				}
				
				lookData = ( newLook ) ? cardItem.cardData.getLook( newLook ) : cardItem.cardData.getLook( cardItem.value );
				if( lookData == null )
				{
					lookData = cardItem.cardData.getLook();
				}
				
				if (petObj["pet"])
				{
					// apply look to pet
					var data:SpecialAbilityData = shellApi.specialAbilityManager.getAbility("pets/pop_follower");
					if (data != null)
					{
						// get current look
						var currentLookData:LookData = data.specialAbility.getLook();
						// iterate through changeable parts
						var ids:Array = [SkinUtils.FACIAL, SkinUtils.EYES, SkinUtils.OVERBODY, SkinUtils.HAT];
						for each (var id:String in ids)
						{
							var currrentLookAspect:LookAspectData = currentLookData.getAspect(id);
							// get aspect to remove
							var lookAspect:LookAspectData = lookData.getAspect(id);
							// if found in current and found in new look then remove from current
							if ((currrentLookAspect != null) && (lookData.getAspect(id) != null))
							{
								// if removing eyes, then set to default eyes
								if (currrentLookAspect.id == SkinUtils.EYES)
								{
									currrentLookAspect.value = "eyes";
								}
								// else set to empty
								else
								{
									currrentLookAspect.value = "empty";
								}
							}
						}
						data.specialAbility.setLook(currentLookData);
					}
				}
				else
				{
					if( this.shellApi.player.has(Skin) )	// apply to player skin
					{
						SkinUtils.removeLook( super.shellApi.player, lookData, isPermanent);
						if(isPermanent)
						{
							super.shellApi.saveLook();
							//super.shellApi.siteProxy.saveLook();
						}
					}
					else									// apply directly to active look, if player does not have skin.  This is not ideal and should be avoided. -bard
					{ 
						/*
						// NOTE :: for now you cannot remove a look unless the Skin is accessible, otherwise can cause issues. -bard
						var lookConverter:LookConverter = new LookConverter();
						var playerLook:LookData = lookConverter.LookDataFromPlayerLook(super.shellApi.profileManager.active.look); 
						playerLook.remove(lookData);
						super.shellApi.profileManager.active.look = lookConverter.playerLookFromLookData(playerLook);
						if(isPermanent)
						{
							super.shellApi.siteProxy.saveLook(null,playerLook);
						}
						*/
					}
				}
			}
		}	
		
		private function activatePower( cardItem:CardItem, cardAction:CardAction ):void
		{
			var trigger:Boolean = false;
			var abilityId:String;
			
			if( cardAction.params )
			{
				abilityId = DataUtils.getString(cardAction.params.byId( ID ));
				trigger = DataUtils.getBoolean(cardAction.params.byId( TRIGGER ));
			}
			
			// if has card value and not zero
			if((DataUtils.validString(cardItem.value)) /*&& (cardItem.value != "0")*/)
			{
				shellApi.specialAbilityManager.addSpecialAbilityById(shellApi.player, cardItem.value, trigger);
			}
			else
			{
				if(!abilityId)
				{
					//Default to special index of 0 in the event cardItem.value isn't valid.
					abilityId = cardItem.cardData.specialIds[DataUtils.useNumber(cardItem.value, 0)];
				}
				
				shellApi.specialAbilityManager.addSpecialAbilityById(shellApi.player, abilityId, trigger);
			}
		}
		
		private function deactivatePower( cardItem:CardItem, cardAction:CardAction ):void
		{
			var abilityId:String;
			if( cardAction.params )
			{
				abilityId = DataUtils.getString( cardAction.params.byId(ID) );
			}
			
			if((DataUtils.validString(cardItem.value)) /*&& (cardItem.value != "0")*/)
			{
				shellApi.specialAbilityManager.removeSpecialAbility(shellApi.player, cardItem.value);
			}
			else
			{
				if(!abilityId)
				{
					//Default to special index of 0 in the event cardItem.value isn't valid.
					abilityId = cardItem.cardData.specialIds[DataUtils.useNumber(cardItem.value, 0)];
				}
				
				shellApi.specialAbilityManager.removeSpecialAbility(shellApi.player, abilityId);
			}
		}
		
		/**
		 * Set userfield in active profile.
		 * By default attempts to store the userfield externally 
		 * // TODO :: could account for additional parmameter to determine whether to save to backend
		 * @param cardItem
		 * @param cardAction
		 */
		private function setUserField( cardItem:CardItem, cardAction:CardAction ):void
		{
			var islandName:String = DataUtils.useString(cardAction.params.byId(ISLAND), super.shellApi.island);
			var fieldName:String = DataUtils.getString(cardAction.params.byId(USERFIELD));
			var value:String = DataUtils.getString(cardAction.params.byId(VALUE));
			if( DataUtils.validString(fieldName) && DataUtils.validString(value) )
			{
				shellApi.setUserField(fieldName, value, islandName, true);
			}
		}
		
		private function printPoster( cardItem:CardItem, cardAction:CardAction ):void
		{
			var path:String = DataUtils.getString(cardAction.params.byId(PATH));
			var xPos:Number = DataUtils.getNumber(cardAction.params.byId(XPOS));
			var yPos:Number = DataUtils.getNumber(cardAction.params.byId(YPOS));
			var xscale:Number = DataUtils.getNumber(cardAction.params.byId(XSCALE));
			var yscale:Number = DataUtils.getNumber(cardAction.params.byId(YSCALE));
			var rotation:Number = DataUtils.getNumber(cardAction.params.byId(ROTATION));
			var pose:String = DataUtils.getString(cardAction.params.byId(AVATAR_POSE));
			var frame:uint = DataUtils.getUint(cardAction.params.byId(AVATAR_FRAME));
			var eyeState:String = DataUtils.getString(cardAction.params.byId(EYES_STATE));
			var eyesAngle:Number = DataUtils.getNumber(cardAction.params.byId(EYES_ANGLE));
			var mouthFrame:String = DataUtils.getString(cardAction.params.byId(MOUTH_FRAME));
			new PrintAvatarPoster(super.shellApi, path, xPos, yPos, xscale, yscale, rotation, pose, frame, eyeState, eyesAngle, mouthFrame);
		}
		
		private function playAudio(cardItem:CardItem, cardAction:CardAction):void
		{
			var audioUrl:String = DataUtils.getString(cardAction.params.byId(URL));
			AudioUtils.play(this.shellApi.currentScene, audioUrl);
		}
		
		private function doShrink(cardItem:CardItem, cardAction:CardAction, shrink:Boolean, player:Boolean):void
		{
			// if shrinking
			if (shrink)
			{
				// get scale from action parameter
				var scale:Number = DataUtils.getNumber(cardAction.params.byId("scale"));
				// set scale to 50% if missing
				if (isNaN(scale))
					scale = 0.5;
				
				if (player)
				{
					CharUtils.setScale(super.shellApi.player, 0.36 * scale);
				}
				else
				{
					// if npcs
					var entityArray:Vector.<Entity> = CharacterGroup(this.shellApi.sceneManager.currentScene.getGroupById("characterGroup")).getNPCs(CharacterGroup.ALLNPCS);
					// for each NPC
					for each (var npc:Entity in entityArray)
					{
						// get original scale (may not be 0.36) and save it
						var origScale:Number = npc.get(Spatial).scaleY;
						MovieClip(npc.get(Display).displayObject).origScale = origScale;
						CharUtils.setScale(npc, origScale * scale);
					}
				}
			}
			else
			{
				// if restoring
				if (player)
				{
					CharUtils.setScale(super.shellApi.player, 0.36);
				}
				else
				{
					// if npcs
					entityArray = CharacterGroup(this.shellApi.sceneManager.currentScene.getGroupById("characterGroup")).getNPCs(CharacterGroup.ALLNPCS);
					// for each NPC
					for each (npc in entityArray)
					{
						origScale = MovieClip(npc.get(Display).displayObject).origScale;
						CharUtils.setScale(npc, origScale);
					}
				}
			}
		}

		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////////// LOAD ASSETS /////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////////// NON_INTERACTIVE ASSETS////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function loadAssets( cardItem:CardItem):void
		{
			if(cardItem.currentElement < cardItem.cardData.assetsData.length)
			{
				var assetData:AssetData = cardItem.cardData.assetsData[ cardItem.currentElement ];//[cardItem.currentElement];
				if( assetData.conditional )
				{
					if( !checkCondition( cardItem.cardData, assetData.conditional ))
					{
						cardItem.currentElement++;
						loadAssets( cardItem);
						return;
					}
				}
				
				var path:String = assetData.assetPath;
				if( DataUtils.validString( path ) )
				{
					super.shellApi.loadFile(shellApi.assetPrefix + path, assetLoaded, cardItem, assetData);
				}
				else if( assetData.id == CARD_CONTENT )	//  if card content path not specifiied use prefix
				{
					super.shellApi.loadFile(shellApi.assetPrefix + cardItem.pathPrefix + ".swf", assetLoaded, cardItem, assetData);
				}
				else if( assetData.id == CARD_BACK )	//  if card content path not specifiied use prefix
				{
					// get id
					var id:String = cardItem.itemId.substr(4);
					var itemNum:int = int(id);
					// if store or pet item
					if ((itemNum >= 3000 && itemNum < 4000) || (itemNum >= 5200 && itemNum < 7000))
					{
						// look for category (mobile will return null)
						var category:String = ItemManager(super.shellApi.itemManager).getStoreItemType(id);
						// if null, then default to paid background for mobile
						if (category == null)
						{
							trace("================= Card Error: store card category not found: " + id);
							category = "PaidLimited";
						}
						super.shellApi.loadFile(shellApi.assetPrefix + "items/shared/" + category + "Background.swf", assetLoaded, cardItem, assetData);
					}
					else
					{
						super.shellApi.loadFile(shellApi.assetPrefix + cardItem.pathPrefix.replace(cardItem.itemId, BACKGROUND) + ".swf", assetLoaded, cardItem, assetData);
					}
				}
			}
			else	// once card assets have been loaded and added, load buttons
			{
				createText( cardItem );	
			}
		}
		
		private function assetLoaded( displayObject:DisplayObjectContainer, cardItem:CardItem, assetData:AssetData):void
		{
			if( assetData.effectData )
			{
				if( assetData.effectData.filters.length > 0 )
				{
					displayObject.filters = assetData.effectData.filters;	//apply filters
				}
			}
			
			if( assetData.id == CARD_BACK )	// use back to define bounds
			{
				cardItem.bounds = DisplayUtils.getBounds( displayObject, DisplayPositions.CENTER );
				displayObject.x = -cardItem.bounds.width/2;
				displayObject.y = -cardItem.bounds.height/2;
			}
			
			cardItem.bitmapHolder.addChild( displayObject );	// add to clip that will be eventually bitmapped
			
			cardItem.currentElement++;
			loadAssets( cardItem);			// recursive
		}
		
		public function createText( cardItem:CardItem ):void
		{
			var textData:TextData;
			var tf:TextField;
			var textFormat:TextFormat;
			var styleFamily:String;
			var styleId:String;
			var styleData:TextStyleData;
			
			for (var i:int = 0; i < cardItem.cardData.textData.length; i++) 
			{
				textData = cardItem.cardData.textData[i];
				
				if( textData.conditional )
				{
					if( !checkCondition( cardItem.cardData, textData.conditional ) )
					{
						continue;
					}
				}
	
				// if an id has not been specified, auto apply one based on index
				if(!textData.id)
				{
					textData.id = ( i == 0 ) ? TITLE : INSTRUCTIONS;	// TEMP
				}
				// get/assign styleFamily
				styleFamily = ( DataUtils.validString( textData.styleFamily ) ) ? textData.styleFamily : TextStyleData.CARD;
				styleId = ( DataUtils.validString( textData.styleId ) ) ? textData.styleId : textData.id;
				styleData = super.shellApi.textManager.getStyleData( styleFamily, styleId );
				
				tf = new TextField();
				tf.embedFonts = true;
				tf.wordWrap = true;
				tf.antiAliasType = AntiAliasType.NORMAL;
				
				// conditional text for web and mobile
				if ((AppConfig.mobile) && (textData.mobile))
				{
					tf.text = textData.mobile;
				}
				else if ((!AppConfig.mobile) && (textData.web))
				{
					tf.text = textData.web;
				}
				else
				{
					tf.text = textData.value;
				}
				
				tf.mouseEnabled = false;
				if( textData.effectData != null )
				{
					tf.filters = textData.effectData.filters;
				}

				tf.width = ( !isNaN(textData.width) ) ? textData.width : (cardItem.bounds.width * .9);
				tf.height = ( !isNaN(textData.height) ) ? textData.height : (cardItem.bounds.height * .2);

				cardItem.bitmapHolder.addChild( tf );		// add to clip that will be eventually bitmapped

				// Position the textfields only
				tf.x = ( !isNaN( textData.xPos ) ) ? textData.xPos : -tf.width/2;
				if( !isNaN( textData.yPos ) )
				{
					tf.y = textData.yPos;
				}
				else if ( styleFamily == TextStyleData.CARD )
				{
					switch (textData.id)
					{
						case TITLE:
						case TITLE_CAMPAIGN:
						case TITLE_MEMBER:
							tf.y = cardItem.bounds.top * .99;
							break;
						
						case INSTRUCTIONS:
						case INSTRUCTIONS_MEMBER:
						case INSTRUCTIONS_MEMBER2:
							tf.y = cardItem.bounds.bottom * .4;
							break;
						
						case LIMITED:
							tf.y = cardItem.bounds.top * 1.16;
							break;
						
						case SUBTITLE:
						case AD_SUBTITLE:
							tf.y = cardItem.bounds.top * 1.02;
							break;
						
						case ADTITLE:						
							tf.y = cardItem.bounds.top * .92;
							break;
						
						case SMALL_AD:
							tf.y = cardItem.bounds.top * .8;
							break;
						
						case COPYRIGHT:
							tf.y = cardItem.bounds.bottom * .73;
							break;
					}
				}

				// apply style // NOTE :: Must do last for some reason, otherwise y position changes. - Bard
				if( styleData != null )
				{
					TextUtils.applyStyle( styleData, tf, textData );
				}
				
				// Causing colors in the style originally not to work.
				/*if( !isNaN( textData.textColor ))
				{
				styleData.color = textData.textColor;
				}
				if( textData.size > 0 && !isNaN( textData.size ))
				{
				styleData.size = textData.size;
				}*/
			}
			
			// non-interactive elemenst finished loading
			cardBaseLoadingComplete( cardItem );
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		//////////////////////////////////////////// INTERACTIVE ASSETS /////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Non-interactive elemenst finished loading.
		 * Start loading interactive elements, such as buttons and special card content
		 * @param cardItem
		 * 
		 */
		private function cardBaseLoadingComplete( cardItem:CardItem ):void
		{
			// If there are radio buttons load them now (card buttons will load after)
			// Otherwise go ahead and load the card button
			cardItem.currentElement = 0;
			if (cardItem.cardData.radioButtonData.length > 0)
			{
				loadRadioButton( cardItem );
			} 
			else 
			{	
				loadButton( cardItem );
			}
		}
		
		protected function loadRadioButton( cardItem:CardItem ):void
		{	
			// Create the Radio Button holder Sprite if it doesn't exist
			// TODO :: Should be able to remove the need for radioButtonHolder. - Bard
			if (!cardItem.radioButtonHolder)
			{
				cardItem.radioButtonHolder = new Sprite();
				cardItem.spriteHolder.addChild(cardItem.radioButtonHolder);
				cardItem.radioButtonHolder.y = CARD_CONTENT_BOUNDS.top * .575;
			}
			
			if(cardItem.currentElement < cardItem.cardData.radioButtonData.length)
			{
				var radioButtonData:CardRadioButtonData = cardItem.cardData.radioButtonData[cardItem.currentElement];
				
				// Set the current radio button value to the value of the first button
				if (cardItem.currentElement == 0)
				{
					cardItem.currentRadioBtnValue = radioButtonData.value;
				}
				
				var assetPath:String = ( DataUtils.validString(radioButtonData.assetPath) ) ? radioButtonData.assetPath : _defaultRadioButtonPath;
				super.shellApi.loadFile(shellApi.assetPrefix + assetPath, radioButtonLoaded, cardItem, radioButtonData );
			}
			else	
			{
				// Center the radio buttons then load standard buttons after radio buttons are complete
				//cardItem.radioButtonHolder.x = 0;//(cardItem.bounds.width / 2);
				
				cardItem.currentElement = 0;
				loadButton( cardItem );
			}
		}
		
		private function radioButtonLoaded( displayObject:DisplayObjectContainer, cardItem:CardItem, radioButtonData:CardRadioButtonData ):void
		{
			var clip:MovieClip = MovieClip( displayObject ).content;
			if (radioButtonData.color)
			{
				ColorUtil.colorize( clip.colorClip, radioButtonData.color );
			}
			if(!isNaN(radioButtonData.alpha))
			{
				clip.colorClip.alpha = radioButtonData.alpha;
			}
			
			//var radiobutton:StandardButton = ButtonCreator.createStandardButton( clip, Command.create( onRadioButtonClicked, cardItem, radioButtonData.val ), cardItem.radioButtonHolder, this );
			var radioButton:MultiStateToggleButton = ButtonCreator.createMultiStateToggleButton( clip, null, cardItem.radioButtonHolder, this );
			radioButton.value = radioButtonData.value;
			radioButton.click.add( Command.create(onRadioButtonClicked, cardItem, radioButton) );
			cardItem.addRadioButton( radioButton );
			var xPos:int = 0;
			var yPos:int = 0;
			var spacePerButton:Number = 39;
			// if store card
			if (int(cardItem.itemId.substr(4)) >= 2000)
			{
				// force buttons to left
				clip.x = CARD_CONTENT_BOUNDS.left + 18;
				yPos = cardItem.cardData.radioButtonData[cardItem.currentElement].yPos;
				if (( isNaN(yPos)) || (yPos == 0))
				{
					var top:Number =  82 - spacePerButton * (cardItem.cardData.radioButtonData.length - 1) / 2;
					clip.y = top + (cardItem.currentElement * spacePerButton) + spacePerButton / 2 + cardItem.cardData.yShift;
				}
				else
				{
					clip.y = yPos;
				}
				xPos = cardItem.cardData.radioButtonData[cardItem.currentElement].xPos;
				if( !isNaN(xPos) && xPos != 0)
				{
					clip.x = xPos;
				}
			}
			else
			{
				spacePerButton = 44;
				xPos = cardItem.cardData.radioButtonData[cardItem.currentElement].xPos;
				if( !isNaN(xPos) )
				{
					clip.x = xPos;
				}
				if( isNaN(xPos) || xPos == 0)
				{
					//var spacePerButton:Number = CARD_CONTENT_BOUNDS.width / cardItem.cardData.radioButtonData.length;
					var left:Number = CARD_CONTENT_BOUNDS.left + CARD_CONTENT_BOUNDS.width/2 - spacePerButton * cardItem.cardData.radioButtonData.length / 2;
					clip.x = left + (cardItem.currentElement * spacePerButton) + spacePerButton / 2;
				}
				
				yPos = cardItem.cardData.radioButtonData[cardItem.currentElement].yPos;
				if( !isNaN(yPos) )
				{
					clip.y = yPos;
				}
				xPos = cardItem.cardData.radioButtonData[cardItem.currentElement].xPos;
				if( !isNaN(xPos) )
				{
					clip.x = xPos;
				}
			}
			
			cardItem.currentElement++;
			loadRadioButton( cardItem );
		}
		
		private function onRadioButtonClicked( e:Event, cardItem:CardItem, radioButton:MultiStateToggleButton ):void
		{
			trace( "onRadioButtonClicked: value: " + radioButton.value);
			cardItem.currentRadioBtnValue = radioButton.value;
			this.updateValue( cardItem, radioButton.value );

			cardItem.selectRadioButton( radioButton );
		}
		
		protected function loadButton( cardItem:CardItem ):void
		{	
			if(cardItem.currentElement < cardItem.cardData.buttonData.length)
			{
				var buttonData:CardButtonData = cardItem.cardData.buttonData[cardItem.currentElement];
				var isVisble:Boolean = true;
				
				if( buttonData.conditional )
				{
					if( !checkCondition( cardItem.cardData, buttonData.conditional ) )			// if condition is not met
					{
						isVisble = false;
					}
				}
				
				// create button
				super.shellApi.loadFile(shellApi.assetPrefix + _defaultButtonPath, buttonLoaded, cardItem, buttonData, isVisble );
			}
			else	
			{
				// initial card loading complete (special card content is handled elsewhere)
				cardItemLoaded( cardItem );
			}
		}
		
		protected function buttonLoaded( displayObject:DisplayObjectContainer, cardItem:CardItem, buttonData:CardButtonData, isVisible:Boolean = true ):void
		{ 
			var clip:MovieClip = MovieClip( displayObject ).content;	// actual button is nested...
			
			// position
			// need room for copyright at bottom of card (was 0.72)
			if( buttonData.y )
			{
				clip.y = buttonData.y;
			}
			else
			{
				clip.y = cardItem.bounds.bottom * 0.69;
				if ( buttonData.index > 0 )
				{
					clip.y -= ( clip.height * 1.05 * buttonData.index );
				}
			}
			// apply label
			ButtonCreator.addLabel(clip.textContainer, buttonData.labelText, FORMAT_BUTTON, ButtonCreator.ORIENT_CENTERED );
			
			// apply filters (could automate this?)
			if( buttonData.effectData )
			{
				if( buttonData.effectData.filters )
				{
					clip.filters = buttonData.effectData.filters;
				}
			}
			
			var btnEntity:Entity = ButtonCreator.createButtonEntity(clip, this, Command.create( onCardButtonClicked, cardItem, buttonData.actions ), cardItem.spriteHolder, null, null, false);
			// keep reference to clip within buttonData (much to my chagrin) necessary if we need to hide buttons while card is open - Bard
			buttonData.entity = btnEntity;
			btnEntity.get(Display).visible = isVisible;
			if(isVisible)
			{
				DisplayUtils.moveToTop(clip);
			}
			
			if(buttonData.disabled || cardItem.disableButtons )
			{
				btnEntity.get(Button).isDisabled = true;
				btnEntity.get(Interaction).lock = true;
			}
			
			cardItem.currentElement++;
			loadButton( cardItem );
		}
		
		///////////////////////////////////// HELPERS /////////////////////////////////////
		
		private function getParamValue( paramId:String, cardData:CardItemData, cardAction:CardAction ):String
		{
			var paramValue:String = "";
			
			var xml:XML = cardAction.params.byId( paramId );
			if(xml != null)
			{
				var xmlList:XMLList = xml.child("conditional");
				if(xmlList!= null)
				{
					var id:String = DataUtils.getString(xmlList.attribute("id")); 
					paramValue = cardData.getConditionalValue(id);
				}
				else
				{
					paramValue = DataUtils.getString(xml);
				}
			}
			return paramValue;
		}
		
		public var cardActivated:Signal;
		private var _cardCreator:CardItemCreator;
		protected var _blockParentClose:Boolean = false;		// TEMP :: Until I fix Tweening for groups
		
		protected static const FORMAT_BUTTON:TextFormat = new TextFormat("Billy Serif", 24, 0x000000);
		
		public static const GROUP_ID:String 		= "cardGroup";
		public static const CARD_BOUNDS:Rectangle 	= new Rectangle(-140, -200, 280, 400);	// TODO :: this shoud be derived from the cards
		public static const CARD_CONTENT_BOUNDS:Rectangle = new Rectangle(-120, -180, 240, 360);
		
		// parameter ids : Assets
		private static const CARD_BACK:String 		= "cardBack";
		private static const CARD_CONTENT:String 	= "cardContent";
		private const BACKGROUND:String 			= "background";
		
		// parameter ids : Text
		protected static const TITLE:String 				= "title";
		protected static const CCG_TITLE:String 			= "ccgtitle";
		protected static const INSTRUCTIONS:String 			= "instructions";
		protected static const TITLE_MEMBER:String 			= "membertitle";
		protected static const INSTRUCTIONS_MEMBER:String 	= "memberinstructions";
		protected static const INSTRUCTIONS_MEMBER2:String 	= "memberinstructions2";
		protected static const TITLE_CAMPAIGN:String		= "campaigntitle";
		protected static const SMALL_AD:String 				= "ad";
		protected static const SUBTITLE:String 				= "subtitle";
		protected static const AD_SUBTITLE:String			= "adsubtitle";
		protected static const ADTITLE:String 				= "adtitle";
		protected static const LIMITED:String 				= "limited";
		protected static const COPYRIGHT:String				= "copyright";
		
		public static const EVENT_TYPE:String				= "eventtype";
		public static const EVENT_CHOICE:String				= "choice";
		public static const EVENT_SUBCHOICE:String			= "subchoice";
		
		// card types
		public static const ISLAND:String		= "island";
		public static const STORE:String		= "store";
		public static const CUSTOM:String		= "custom";
		public static const PETS:String			= "pets";
		
		// parameter ids : CardActions
		public static const URL:String 				= "urlId";
		private static const CLASS_NAME:String 		= "className";
		private static const TRIGGER:String 		= "trigger";
		private static const ID:String 				= "id";
		private static const ITEM:String 			= "item";
		private static const PERMANENT:String 		= "permanent";
		private static const EVENT:String 			= "event";
		private static const SAVE:String 			= "save";
		private static const SHOW:String			= "show";
		private static const USERFIELD:String 		= "userField";
		private static const VALUE:String			= "value";
		private static const PATH:String			= "path";
		private static const XPOS:String			= "xpos";
		private static const YPOS:String			= "ypos";
		private static const XSCALE:String			= "xscale";
		private static const YSCALE:String			= "yscale";
		private static const ROTATION:String		= "rotation";
		private static const EYES_ANGLE:String		= "eyesrotation";
		private static const EYES_STATE:String		= "eyestate";
		private static const MOUTH_FRAME:String		= "mouthframe";
		private static const AVATAR_POSE:String 	= "pose";
		private static const AVATAR_FRAME:String  	= "frame";
		private static const NONE:String  			= "none";
		
		// tracking 
		public static const CARD_USED:String = "CardUsed"; 
		
		//private var _overlayContainer:DisplayObjectContainer;
		//private const _defaultTextFormat:TextFormat = new TextFormat("CreativeBlock BB", 12, 0x000000);
		protected const _defaultButtonPath:String = "ui/card/card_btn.swf";
		private const _defaultRadioButtonPath:String = "ui/card/radio_btn.swf";
	}
}

