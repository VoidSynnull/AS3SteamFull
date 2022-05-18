package game.ui.costumizer 
{
	
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Player;
	import game.components.entity.character.Rig;
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.MetaPart;
	import game.components.entity.character.part.SkinPart;
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.components.ui.GridSlot;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Pop;
	import game.data.character.CharacterData;
	import game.data.character.LookAspectData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.comm.PopResponse;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.ui.ToolTipType;
	import game.data.ui.TransitionData;
	import game.managers.LanguageManager;
	import game.nodes.entity.character.CharacterUpdateNode;
	import game.proxy.GatewayConstants;
	import game.scene.template.CharacterGroup;
	import game.scene.template.SceneUIGroup;
	import game.systems.entity.DrawLimbSystem;
	import game.systems.entity.SkinSystem;
	import game.systems.entity.character.part.FlipPartSystem;
	import game.systems.timeline.TimelineRigSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayPositions;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Costumizer
	 * @author Bard McKinley/Drew Martin
	 */
	public class Costumizer extends Popup 
	{
		private var costumizerDelegate:CostumizerDelegate;
		
		public function Costumizer(container:DisplayObjectContainer = null, lookData:LookData = null, ownedLook:Boolean = false, skipNPCCheck:Boolean = false, isPet:Boolean = false ) 
		{
			_costumeLook = lookData;
			_ownedLook = ownedLook;
			_skipNPCCheck = skipNPCCheck;
			_isPet = isPet;
			
			if (lookData != null)
			{
				if (isPet)
					_costumeLook.variant = CharacterCreator.VARIANT_PET_BABYQUAD;
				else if (lookData.variant == null)
					_costumeLook.variant = CharacterCreator.VARIANT_HUMAN;
			}
			
			super(container);
			super.id = GROUP_ID;
		}
		
		//// ACCESSORS ////
		
		public function get delegate():CostumizerDelegate { return costumizerDelegate; }
		public function set delegate(newDelegate:CostumizerDelegate):void {
			costumizerDelegate = newDelegate;
		}
		
		public override function destroy():void 
		{
			// revert DrawLimbSystem redrawn threshold to default
			var limbSystem:DrawLimbSystem = super.getSystem( DrawLimbSystem ) as DrawLimbSystem;
			limbSystem.redrawnThreshold = limbSystem.THRESHOLD_DEFAULT;
			
			// revert ignore camera scale
			var skinSystem:SkinSystem = super.getSystem( SkinSystem ) as SkinSystem;
			skinSystem.ignoreCameraScale = false;
			
			// add TimelineRigSystem back
			super.groupManager.addSystem( new TimelineRigSystem() );
			
			super.destroy();
		}
		
		public override function init(container:DisplayObjectContainer = null):void 
		{
			super.groupPrefix = "ui/costumizer/";
			super.screenAsset = "costumizer.swf";
			
			// config transition
			var transitionIn:TransitionData = new TransitionData();
			transitionIn.duration = .9;
			transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			transitionIn.endPos = new Point(0, 0);
			transitionIn.ease = Bounce.easeOut;
			var transitionOut:TransitionData = transitionIn.duplicateSwitch(Sine.easeIn);
			transitionOut.duration = .3;
			this.darkenAlpha = 0.6;
			super.config(transitionIn, transitionOut, false, false, true, false);
			onNPCSelected = new Signal(Entity);
			onNPCPartSelected = new Signal(Entity);
			onPartTraySelected = new Signal(Entity);
			allCharsLoaded = new Signal(Costumizer);
			
			// track
			super.shellApi.track( COSTUMIZER_OPENED, null, null, SceneUIGroup.UI_EVENT);
			
			_charGroup = super.getGroupById("characterGroup" ) as CharacterGroup;
			if( _charGroup == null )
			{
				_charGroup = super.addChildGroup( new CharacterGroup() ) as CharacterGroup;
			}
			
			super.init(container);
			super.load();
		}
		
		public override function loaded():void 
		{
			super.preparePopup(); // handles some of the standard Popup preparation
			
			// adjust systems
			DrawLimbSystem( super.getSystem( DrawLimbSystem ) ).redrawnThreshold = 1;	// adjust DrawLimbSystem for smoother redrawn to account for larger avatar size
			super.removeSystemByClass( TimelineRigSystem );	// NOTE :: Remove this system so that animations do not overrride parts	
			SkinSystem(super.getSystem( SkinSystem )).ignoreCameraScale = true;	// ignore camera scale when bitmapping parts
			
			var clip:MovieClip;
			
			// scale to fit viewport
			clip = this.screen.content;
			clip.panel_L.background.width = clip.panel_R.background.width = clip.panel_R.x = clip.select_message.x = shellApi.viewportWidth/2;
			clip.panel_L.background.height = clip.panel_R.background.height = clip.panel_Parts.y = shellApi.viewportHeight;
			clip.panel_L.shadow.x = clip.panel_L.character.x = clip.panel_R.shadow.x = clip.panel_R.character.x = clip.panel_R.spotlight.x = shellApi.viewportWidth/4;
			clip.panel_L.shadow.y = clip.panel_L.character.y = clip.panel_R.shadow.y = clip.panel_R.character.y = shellApi.viewportHeight * .9;
			clip.panel_Parts.background.width = shellApi.viewportWidth;
			
			clip.panel_Top.acceptBtn.x = this.shellApi.viewportWidth * 0.5 + 60;
			clip.panel_Top.cancelBtn.x = this.shellApi.viewportWidth - 55;
			clip.panel_L.target.y = this.shellApi.viewportHeight - 55;
			clip.panel_R.addLook.x = this.shellApi.viewportWidth * 0.5 - 55;
			clip.panel_R.addLook.y = this.shellApi.viewportHeight - 55;
			
			// set message text
			TextUtils.convertText( clip.select_message.tf, new TextFormat("Billy Serif", 24), LanguageManager(shellApi.getManager(LanguageManager)).get("shared.costumizer." + SELECT_NPC, "Select A Character"));
			
			// bitmap
			this.convertToBitmap(clip.panel_L.background);
			this.convertToBitmap(clip.panel_R.background);
			this.convertToBitmap(clip.panel_L.shadow);
			this.convertToBitmap(clip.panel_R.shadow);
			this.convertToBitmap(clip.panel_R.spotlight);
			this.convertToBitmap(clip.panel_Parts.background);
			this.convertToBitmap(clip.select_message);
			
			// NPC SELECTION
			determineNpcs();
			
			// if using customizer icon and no NPCs to select
			if ((_costumeLook == null) && (_screenNpcNodes.length == 0))
			{
				var flipSys:FlipPartSystem = FlipPartSystem(super.getSystem( FlipPartSystem ));
				if(flipSys != null)
					flipSys.paused = false;
				super.close();
				var uiGroup:SceneUIGroup = super.parent.getGroupById( SceneUIGroup.GROUP_ID ) as SceneUIGroup;
				uiGroup.askForConfirmation(SceneUIGroup.NO_NPCS_TO_SELECT, uiGroup.removeConfirm, uiGroup.removeConfirm);
				return;
			}
			
			// CREATE CHARACTERS
			
			var scale:Number = CHAR_SCALE;
			
			// get pet look
			if (_isPet)
			{
				var data:SpecialAbilityData = shellApi.specialAbilityManager.getAbility("pets/pop_follower");
				if (data == null)
				{
					trace("Costumizer: no active pet found to display!");
				}
				else
				{
					_playerLook = data.specialAbility.getLook();
				}
				scale = PET_SCALE;
			}
			// get player look
			else
			{
				_playerLook = SkinUtils.getLook(this.shellApi.player, true);
				if( _playerLook == null )
				{
					_playerLook = new LookConverter().lookDataFromPlayerLook(super.shellApi.profileManager.active.look);
				}
			}
			
			// create player dummy
			var variant:String = CharacterCreator.VARIANT_HUMAN;
			if ((_costumeLook != null) && (_costumeLook.variant != null))
				variant = _costumeLook.variant;
			_player = _charGroup.createDummy( PLAYER, _playerLook, CharUtils.DIRECTION_LEFT, CharacterCreator.VARIANT_HUMAN, this.screen.content.panel_R.character, this, onCharLoaded, true, scale);
			EntityUtils.visible( _player, false, true );
			var skin:Skin = new Skin();
			skin.allowSpecialAbilities = false;
			_player.add(skin);
			_playerGender = _playerLook.getValue( SkinUtils.GENDER );
			_numLoadingChars++;
			
			// create npc dummy
			if( _costumeLook )
			{
				this.setModelLook(_costumeLook);
			}
			
			// CREATE PANELS
			//Top Panel
			_topPanel = new UIDrawer(this, this.screen.content.panel_Top, true, "TopPanel");
			_topPanel.offscreenEdge = UIDrawer.OFFSCREEN_TOP;
			_topPanel.offscreenY = -(MovieClip(this.screen.content.panel_Top).height + 100 );
			_topPanel.onscreenY = 0;
			
			//Left Panel
			_leftPanel = new UIDrawer(this, this.screen.content.panel_L, true, "LeftPanel");
			_leftPanel.offscreenEdge = UIDrawer.OFFSCREEN_LEFT;
			_leftPanel.offscreenX = -super.shellApi.viewportWidth/2;
			_leftPanel.onscreenX = 0;
			
			//Right Panel
			_rightPanel = new UIDrawer(this, this.screen.content.panel_R, true, "RightPanel");
			_rightPanel.offscreenEdge = UIDrawer.OFFSCREEN_RIGHT;
			_rightPanel.offscreenX = super.shellApi.viewportWidth;
			_rightPanel.onscreenX = super.shellApi.viewportWidth/2;
			
			//Parts Panel
			_partsPanel = new UIDrawer(this, this.screen.content.panel_Parts, false, "PartTray");
			_partsPanel.offscreenEdge = UIDrawer.OFFSCREEN_BOTTOM;
			_partsPanel.offscreenY = super.shellApi.viewportHeight;
			_partsPanel.onscreenY = super.shellApi.viewportHeight - MovieClip(this.screen.content.panel_Parts).height;
			_partsPanel.visible = MovieClip(this.screen.content.panel_Parts).visible = false;
			_partsPanel.exitCallback = hidePartsTray;
			
			
			// CREATE BUTTONS
			//Cancel Button
			clip = this.screen.content.panel_Top.cancelBtn;
			this._cancelButton = ButtonCreator.createButtonEntity(clip, this, onCancel, null, null, null, true, true );
			
			//Accept Button
			clip = this.screen.content.panel_Top.acceptBtn;
			this._acceptButton = ButtonCreator.createButtonEntity(clip, this, onAccept, null, null, null, true, true);
			
			// Create Target button if available npcs are within screen and not pet
			clip = this.screen.content.panel_L.target;
			if (( _screenNpcNodes.length > 0 ) && (!_isPet))
			{
				_targetButton = ButtonCreator.createButtonEntity(clip, this, onTargetNpcClicked, null, null, null, true, true);
				var closeContainer:Sprite = new Sprite()
				this.screen.content.addChildAt( closeContainer, 0 );
				super.loadCloseButton( DisplayPositions.TOP_RIGHT, 50, 50, true, closeContainer );
			}
			else
			{
				clip.parent.removeChild(clip);
			}
			
			// Create PartsTrayButton (opens & closes parts tray )
			clip = this.screen.content.panel_L.tray_button;
			clip.x = 55;
			clip.y = this.shellApi.viewportHeight - 150;
			
			if (_isPet)
			{
				clip.parent.removeChild(clip);
			}
			else
			{
				_partsTrayButton = ButtonCreator.createButtonEntity( clip, this, togglePartTray );
				var sleep:Sleep = new Sleep();
				_partsTrayButton.add( sleep );
				if( _costumeLook == null )	// hide button if costumizer opens without a look
				{
					EntityUtils.visible( _partsTrayButton, false );
					sleep.sleeping = true;
				}
			}
			
			this.setupCloset();
			
			// if a costume look wasn't passed & screen npcs are available go directly to screen npc selection mode
			if( !_costumeLook && _screenNpcNodes.length > 0 && !_skipNPCCheck)
			{
				super.transitionIn = null;
				_topPanel.visible = _leftPanel.visible = _rightPanel.visible = _partsPanel.visible = false;
				_panelsVisible = false;
				super.open();
				targetNpc(); // go directly to npc selection
			}
				// if costume was passed or no screen npcs are available then open costumizer panels once chars have finsihed loading
			else
			{
				_panelsVisible = true;
			}
			
			this.groupReady();
		}
		
		private function setupCloset():void
		{
			var panel:MovieClip = this.screen.content.panel_R;
			var shouldShowClosetDrawer:Boolean = delegate ? delegate.shouldIncludeCloset() : true;
			if (_isPet)
				shouldShowClosetDrawer = false;
			
			if (shouldShowClosetDrawer) {
				panel.closet.x = this.shellApi.viewportWidth * 0.5 - 55;
				panel.closet.y = this.shellApi.viewportHeight - 150;
				ButtonCreator.createButtonEntity(panel.closet, this, openCloset);
				
				panel.addLook.x = this.shellApi.viewportWidth * 0.5 - 55;
				panel.addLook.y = this.shellApi.viewportHeight - 55;
				ButtonCreator.createButtonEntity(panel.addLook, this, addLookToCloset);
			} else {
				panel.closet.visible = panel.addLook.visible = false;
			}
		}
		
		public function openCloset(entity:Entity = null):Closet
		{
			var closet:Closet = new Closet(this.groupContainer);
			closet.closetLookClicked.add(this.closetLookClicked);
			this.addChildGroup(closet);
			
			return closet;
		}
		
		private function closetLookClicked(lookData:LookData):void
		{
			_partsTrayButton.get(Display).visible = true;
			_ownedLook = true;
			this.setModelLook(lookData, true);
			this.unpause(true);		// so that costumizer can start updating character
		}
		
		private function setModelLook(lookData:LookData, applyPlayerBase:Boolean = false):void
		{
			this._costumeLook = lookData.duplicate();
			
			if( _ownedLook )
			{
				this._costumeLook.applyBaseLook(_playerLook, _isPet);
			}
			this._costumeLook.fillWithEmpty();
			
			// create a new dummy if one has yet to be created, or if the dummy's variant has changed
			if( !_model || _model.get(Character).variant != this._costumeLook.variant )
			{
				var data:CharacterData 	= new CharacterData();
				data.id					= MODEL;
				data.look				= this._costumeLook;
				data.dynamicParts		= true;
				if (_isPet)
					data.scale			= PET_SCALE;
				else
					data.scale			= CHAR_SCALE;
				data.direction 			= CharUtils.DIRECTION_RIGHT;
				data.event 				= GameEvent.DEFAULT;
				data.variant			= this._costumeLook.variant;
				
				if(data.variant == CharacterCreator.VARIANT_MANNEQUIN)
				{
					data.type = CharacterCreator.TYPE_PORTRAIT;
				}
				else
				{
					data.type = CharacterCreator.TYPE_DUMMY;
				}
				
				this.removeEntity(_model);
				
				_model = _charGroup.createDummyFromData(data, this.screen.content.panel_L.character, this, onCharLoaded);
				EntityUtils.visible( _model, false, true );
				var skin:Skin = new Skin();
				skin.allowSpecialAbilities = false;
				_model.add(skin);
			}
			else
			{
				SkinUtils.applyLook(_model, this._costumeLook, true, onCharLoaded);
			}
			
			_numLoadingChars++;
		}
		
		// TODO :: should we give a warning of a full closet regardless of platform? - bard
		private function addLookToCloset(entity:Entity):void
		{
			//Use non-permanent look since the dummy's look isn't permanently applied.
			var lookData:LookData = SkinUtils.getLook(this._player, false);
			if( lookData != null )
			{
				shellApi.saveLookToCloset( lookData, onClosetLookSaved, onClosetFull );
			}
			else
			{
				trace("Error :: Costumizer : addLookToCloset was not able to retrive LookDat from given Entity");
			}
		}
		
		private function onClosetFull():void
		{
			this.createDialogPopup("shared.costumizer.maxLooks", this.CLOSET_FULL_MESSAGE);
		}
		
		private function onClosetLookSaved(response:PopResponse):void
		{
			trace("Save Look PopResponse:", response.data.answer, response.succeeded, response.status, response.error, response.toString());
			
			//There is no available item ID. All closet "slots" (1-30) are filled.
			if(response.status == GatewayConstants.AMFPHP_NO_AVAILABLE_ITEM)
			{
				onClosetFull();
			}
				//This happens when a guest attempts to save a look to a closet they don't have.
			else if(response.status == GatewayConstants.AMFPHP_UNVALIDATED_USER)
			{
				this.createDialogPopup("shared.costumizer.saveGame", this.SAVE_FOR_CLOSET);
			}
			else if(response.status == GatewayConstants.AMFPHP_PROBLEM)
			{
				this.createDialogPopup("", this.CLOSET_ERROR);
			}
			else
			{
				this.shellApi.saveGame();
			}
		}
		
		private function createDialogPopup(languageStringId:String, defaultText:String):void
		{
			defaultText = (shellApi.languageManager).get(languageStringId, defaultText);
			
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, defaultText)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.groupContainer);
		}
		
		protected override function handleCloseClicked(...args):void 
		{
			if( !_topPanel.visible )	// closing npc selection prior to viewing costumizer panels, in this case close costumizer
			{
				super.transitionOut = null;
				super.handleCloseClicked();
			}
			else						// closing npc selection after viewing costumizer panels, in this case return to costumizer view
			{
				_topPanel.toggle();
				_leftPanel.toggle();
				_rightPanel.toggle();
			}
		}
		
		/**
		 * Called when popup has finsihed it's opening transition. 
		 * At this point we want the panels that begin off screen to become visible
		 */
		private function onOpenComplete():void
		{
			_partsPanel.visible = true;
		}
		
		/**
		 * Makes appropriate panels open or close based on value passed.
		 * @param flag
		 */
		private function showPanels( flag:Boolean = true ):void
		{
			if( flag && !_panelsVisible )
			{
				_topPanel.visible = _leftPanel.visible = _rightPanel.visible = _partsPanel.visible = flag;
				_panelsVisible = flag;
			}
			
			_topPanel.show( flag );
			_leftPanel.show( flag );
			_rightPanel.show( flag );
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////// ACCEPT/CANCEL /////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function onCancel(button:Entity):void
		{
			var flipSystem:FlipPartSystem = FlipPartSystem(super.getSystem( FlipPartSystem ));
			if(flipSystem != null)
				flipSystem.paused = false;
			super.close();
		}
		
		private function onAccept(button:Entity):void
		{
			// get new player look
			var newPlayerLook:LookData = SkinUtils.getLook( _player, false );
			
			if (_isPet)
			{
				// apply look to pet
				var data:SpecialAbilityData = shellApi.specialAbilityManager.getAbility("pets/pop_follower");
				if (data != null)
				{
					data.specialAbility.setLook(newPlayerLook);
				}
			}
			else
			{
				// make current look permanent & save. Both save to server and save to local profile data happen in ShellApi.saveLook - wrb
				if( shellApi.player.has(Skin) )
				{
					SkinUtils.applyLook( shellApi.player, newPlayerLook );
				}
				
				super.shellApi.track( COSTUME_ACCEPT );
				// NOTE :: Trying to funnel calls to siteProxy through shellApi, will need to make sure this still achieves
				//super.shellApi.siteProxy.saveLook( null, newPlayerLook );
				super.shellApi.saveLook( newPlayerLook );
				
				if (delegate) {
					delegate.playerDidAcceptNewLook();
				}
			}
			var flipSystem:FlipPartSystem = FlipPartSystem(super.getSystem( FlipPartSystem ));
			if(flipSystem != null)
				flipSystem.paused = false;
			super.close();
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////// PART TRAY ///////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function togglePartTray(buttonEntity:Entity):void
		{
			if(_costumeLook)
			{
				var button:Button = buttonEntity.get(Button);
				if(!button.isSelected)
				{
					_partsPanel.visible = true;
				}
				_partsPanel.toggle();
				button.toggleSelected();
			}
		}
		
		private function hidePartsTray():void
		{
			_partsPanel.visible = false;
			_partsPanel.show(false);
			Button(_partsTrayButton.get(Button)).isSelected = false;
		}
		
		private function createPartTray():void
		{
			// charater Data used to create mannequins
			_dummyData 				= new CharacterData();
			_dummyData.type			= CharacterCreator.TYPE_PORTRAIT;
			_dummyData.variant		= CharacterCreator.VARIANT_MANNEQUIN;
			_dummyData.dynamicParts	= false;
			_dummyData.scale		= MANNEQUIN_SCALE;
			_dummyData.direction 	= CharUtils.DIRECTION_RIGHT;
			_dummyData.event 		= GameEvent.DEFAULT;
			
			var partArray:Vector.<String> = COSTUME_PARTS;
			if (_isPet)
				partArray = PET_PARTS;
			
			_partSlots = new Vector.<Entity>(partArray.length);
			_partSlotDummies = new Vector.<Entity>(partArray.length);
			
			var rig:Rig = _model.get( Rig );
			var slotEntity:Entity;
			var lookAspect:LookAspectData;
			var queueIndex:int = 0;
			var partEntity:Entity;
			
			// create an Entity for each possible slot, slot order will follow COSTUME_PARTS order
			for (var i:int = 0; i < partArray.length; i++)
			{
				slotEntity = new Entity();
				_partSlots[i] = slotEntity;
				
				var gridSlot:GridSlot = new GridSlot();
				gridSlot.index = i;
				gridSlot.id = partArray[i];
				slotEntity.add( gridSlot );
				
				slotEntity.add( new Sleep() );
				
				// if costume look is available, check for look
				if( _costumeLook )
				{
					lookAspect = _costumeLook.getAspect( gridSlot.id );
					if( lookAspect )
					{
						partEntity = rig.getPart( gridSlot.id );
						if( checkPartValidity( partEntity ) )	// check skin part for validity (part should already be loaded on dummy) 
						{
							super.loadFile( PART_BTN_ASSET, onPartBtnLoaded,  slotEntity, lookAspect, queueIndex );
							queueIndex++;
							continue;
						}
					}
				}
				
				super.loadFile( PART_BTN_ASSET, onPartBtnLoaded,  slotEntity );
			}
		}
		
		private function onPartBtnLoaded( asset:MovieClip, slotEntity:Entity, lookAspect:LookAspectData = null, queueIndex:int = -1 ):void
		{
			// complete slotEntity creation
			var btnClip:MovieClip = asset.content;
			ButtonCreator.assignButtonEntity( slotEntity, btnClip, this, onPartBtnClicked, this.screen.content.panel_Parts.btn_container, null, null, false ); 
			
			Spatial( slotEntity.get(Spatial) ).y = PART_BTN_BUFFER + btnClip.height/2;
			Sleep( slotEntity.get(Sleep) ).ignoreOffscreenSleep = true;
			super.addEntity( slotEntity );
			
			if( lookAspect )
			{
				activatePartButton( slotEntity, lookAspect, queueIndex );
			}
			else
			{
				deactivatePartButton( slotEntity );
			}
		}
		
		private function resetPartTray( charEntity:Entity ):void
		{
			var rig:Rig = _model.get( Rig );
			var partSlot:Entity;
			var lookAspect:LookAspectData;
			var gridSlot:GridSlot;
			var queueIndex:int = 0;
			var partEntity:Entity;
			for (var i:int = 0; i < _partSlots.length; i++) 
			{
				partSlot = _partSlots[i];
				gridSlot = partSlot.get(GridSlot);
				lookAspect = _costumeLook.getAspect( gridSlot.id );
				// TODO :: check skin part for validity (part should already be loaded on dummy) 
				if( lookAspect )
				{
					partEntity = rig.getPart( gridSlot.id );
					if( checkPartValidity( partEntity ) )	// check skin part for validity (part should already be loaded on dummy)
					{
						activatePartButton( partSlot, lookAspect, queueIndex );
						queueIndex++;
						continue;
					}
				}
				
				deactivatePartButton( partSlot );
			}
		}
		
		protected function getPartButtonById( partId:String ):Entity
		{
			var partSlot:Entity;
			for (var i:int = 0; i < _partSlots.length; i++) 
			{
				partSlot = _partSlots[i];
				if( GridSlot(partSlot.get(GridSlot)).id == partId )
				{
					return partSlot;
				}
			}
			return null;
		}
		
		private function activatePartButton( slotEntity:Entity, lookAspect:LookAspectData, queueIndex:int  ):void
		{
			var gridSlot:GridSlot = slotEntity.get(GridSlot);
			Sleep(slotEntity.get(Sleep)).sleeping = false;
			
			// make button visible
			var display:Display = slotEntity.get( Display );
			display.visible = true;
			
			var lookData:LookData = new LookData();
			lookData.applyAspect( lookAspect );
			
			var dummyEntity:Entity = _partSlotDummies[ gridSlot.index ];
			var npc_container:MovieClip = MovieClip(display.displayObject).npc_container.empty;
			if( dummyEntity == null )	// check to see if a dummy has been created for the button, if not create a new one.
			{
				// assign unique id and look to mannequin CharacterData
				var uniqueDummyData:CharacterData = _dummyData.duplicate();
				// if pet, then set variant instead of mannequin
				if (_isPet)
					uniqueDummyData.variant = _costumeLook.variant;
				uniqueDummyData.id	= "partDummy" + gridSlot.index;
				uniqueDummyData.look = lookData;
				uniqueDummyData.position = _partTrayOffsets[gridSlot.index];
				
				dummyEntity = _charGroup.createDummyFromData( uniqueDummyData, npc_container, this);
				_partSlotDummies[ gridSlot.index ] = dummyEntity;
			}
			else
			{
				SkinUtils.applyLook( dummyEntity, lookData );
				Sleep(dummyEntity.get(Sleep)).sleeping = false;
			}
			
			// reposition in tray
			const width:Number = PART_BTN_BUFFER + 98; //~98 is the width of the button asset
			var spatial:Spatial = slotEntity.get(Spatial);
			spatial.x = queueIndex * ( width ) + (width + PART_BTN_BUFFER)/2;
			
			// determine if button should be selected (if player is already wearing the part)
			var playerLookAspect:LookAspectData = SkinUtils.getLookAspect( _player, lookAspect.id );
			if( playerLookAspect.isEqual(lookAspect) )
			{
				Button( slotEntity.get(Button) ).isSelected = true;
			}
		}
		
		private function deactivatePartButton( slotEntity:Entity ):void
		{
			// make button visible
			var display:Display = slotEntity.get( Display );
			display.visible = false;
			
			// put dummy character to sleep?
			var gridSlot:GridSlot = slotEntity.get(GridSlot);
			var dummyEntity:Entity = _partSlotDummies[ gridSlot.index ];
			if( dummyEntity != null )	// check to see if a dummy has been created for the button, if not create a new one.
			{
				Sleep(dummyEntity.get(Sleep)).sleeping = true;
			}
			Sleep(slotEntity.get(Sleep)).sleeping = false;
		}
		
		private function onPartBtnClicked( slotEntity:Entity ):void
		{
			var gridSlot:GridSlot = slotEntity.get(GridSlot);
			var lookAspect:LookAspectData = _costumeLook.getAspect( gridSlot.id );
			var button:Button = slotEntity.get(Button);
			var playerPartEntity:Entity = CharUtils.getPart( _player, lookAspect.id );
			
			if( button.isSelected )	// remove look from player
			{
				var skinEntity:Entity
				if( removePart( playerPartEntity ) )
				{
					button.isSelected = false;
				}
			}
			else					// apply look npc to player
			{
				button.isSelected = true;
				addPart( lookAspect.id, lookAspect.value );
			}
			
			onPartTraySelected.dispatch(slotEntity);
		}		
		
		/////////////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////////// NPC TARGET //////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Creates a list of costumizable npcs in scene
		 */
		private function determineNpcs():void
		{
			_screenNpcNodes.length = 0;
			
			var background:DisplayObjectContainer = (shellApi.screenManager).backgroundContainer;
			
			var npcs:NodeList = this.systemManager.getNodeList(CharacterUpdateNode);
			
			for(var node:CharacterUpdateNode = npcs.head; node; node = node.next)
			{
				if(node.entity.get(Player)) continue;
				if(!node.entity.get(Display).visible || node.entity.get(Display).alpha == 0) continue;
				
				if(node.character.costumizable)
				{
					if(background.hitTestObject(node.display.displayObject))
					{
						_screenNpcNodes.push(node);
					}
				}
			}
		}
		
		private function onTargetNpcClicked(button:Entity):void
		{
			targetNpc();
		}
		
		private function targetNpc():void
		{
			_leftPanel.toggle();
			_rightPanel.toggle();
			_topPanel.toggle();
			hidePartsTray();
			
			var sceneScale:Number = CameraSystem(super.getSystem( CameraSystem )).scale;
			
			var screenContainer:DisplayObjectContainer = this.screen;
			
			for each(var node:CharacterUpdateNode in _screenNpcNodes )
			{
				// add filter before bitmapping
				var filterDist:int = 4;
				
				var display:DisplayObject = node.display.displayObject;
				
				display.filters = [new DropShadowFilter(0, 0, 0xFFFFFF, 1, filterDist, filterDist, 12, BitmapFilterQuality.HIGH)];
				
				// bitmap (multiply by 2 to improve quality degredation caused by filters)
				var scale:Number = (node.spatial.scale * sceneScale) * 2;
				
				var bounds:Rectangle = display.getBounds(display);
				bounds.inflate(filterDist * 2, filterDist * 2);
				
				var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite(display, bounds, scale, false, screenContainer);
				super.storeBitmapWrapper(wrapper);
				screenContainer.setChildIndex(wrapper.sprite, 0);
				
				// adjust scale to account for possible scene scaling
				wrapper.sprite.scaleX *= sceneScale;
				wrapper.sprite.scaleY *= sceneScale;
				
				// remove filter
				display.filters = null;
				
				// position bitmap
				var point:Point = DisplayUtils.localToLocal(display, screenContainer);
				wrapper.sprite.x = point.x;
				wrapper.sprite.y = point.y;
				
				// add interaction & roll over
				var bitmapEntity:Entity = EntityUtils.createSpatialEntity(this, wrapper.sprite);
				var interaction:Interaction = InteractionCreator.addToEntity(bitmapEntity, [InteractionCreator.CLICK]);
				interaction.click.addOnce(Command.create( onNpcSelected, node.entity ));
				ToolTipCreator.addUIRollover(bitmapEntity, ToolTipType.CLICK);
				
				_clickableNPCs.push(bitmapEntity);
			}
		}
		
		/**
		 * Triggered on scene npc selection.
		 * @param button
		 * @param npcEntity
		 */
		private function onNpcSelected( button:Entity, npcEntity:Entity):void
		{
			while(_clickableNPCs.length > 0)
			{
				this.removeEntity(_clickableNPCs.pop());
			}
			
			// TODO :: don't open panels until chars/look has been loaded
			if( !_panelsVisible )
			{
				_topPanel.visible = _leftPanel.visible = _rightPanel.visible = _partsPanel.visible = true;
				_panelsVisible = true;
			}
			_topPanel.toggle();
			_leftPanel.toggle();
			_rightPanel.toggle();
			
			EntityUtils.visible( _partsTrayButton, true );	// make parts button visible
			Sleep(_partsTrayButton.get( Sleep )).sleeping = false;
			
			var lookData:LookData 	= SkinUtils.getLook(npcEntity);
			var character:Character = npcEntity.get(Character);
			lookData.variant = character.variant;
			_ownedLook = false;
			this.setModelLook(lookData);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "cloth_flap_02.mp3");
			onNPCSelected.dispatch(npcEntity);	// dispatch selection for anyone whose interested
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////////// DUMMY SETUP //////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function onCharLoaded( charEntity:Entity ):void
		{
			EntityUtils.getDisplayObject( charEntity ).mouseChildren = true;
			Character(charEntity.get(Character)).costumizable = false;
			
			var id:String; 
			
			if( charEntity == _player )
			{
				id = PLAYER;
			}
			else
			{
				id = MODEL;
				Timeline(charEntity.get(Timeline)).nextIndex = 10;	//offset animation so they are not in sync
				
				// once npc has finished loading create/reset part tray 
				// need character to complete loading first so we can check part MetaData for validity.
				if( _partSlots == null ){
					createPartTray();
				}
				else{
					resetPartTray( _model );
				}
			}
			
			// Set eyes TODO :: Not sure why I have to do this, need to investigate why eyes aren't getting set. - bard
			if(charEntity.get(Npc))
			{
				SkinUtils.setEyeStates( charEntity, SkinUtils.getSkinPart(charEntity, SkinUtils.EYE_STATE).permanent );
			}
			
			var sleep:Sleep = charEntity.get( Sleep )
			sleep.sleeping = false;
			
			var rig:Rig = charEntity.get( Rig );
			var partsArray:Vector.<String> = COSTUME_PARTS;
			if (_isPet)
				partsArray = PET_PARTS;
			for (var i:int = 0; i < partsArray.length; i++) 
			{
				makePartSelectable(id, rig, partsArray[i]);
			}
			
			_numLoadingChars--;
			if( _numLoadingChars == 0 )
			{
				allCharsLoaded.dispatch(this);
				if( !super.isOpened )
				{
					super.open(onOpenComplete);
				}
			}
			
			// give system some time to finalize character before making visible
			SceneUtil.delay( this, 4, Command.create(EntityUtils.visible, charEntity ) ).countByUpdate = true;
		}
		
		private function makePartSelectable(id:String, rig:Rig, partId:String ):void
		{
			var partEntity:Entity = rig.getPart(partId);
			if(!partEntity) return;
			
			var skinPart:SkinPart = partEntity.get( SkinPart );
			if( skinPart )
			{
				if( id == PLAYER )	// is player, part is clicked remove from player
				{
					if( !checkPartEmpty( skinPart ) )
					{
						addInteraction( partEntity, onPlayerPartClicked );
					}
				}
				else				// is npc, part is clicked apply to player
				{
					if( checkPartValidity( partEntity ) )
					{
						addInteraction( partEntity, onNpcPartClicked );
					}
					else
					{
						removeInteraction(partEntity);
					}
				}
			}
		}
		
		private function checkPartValidity( partEntity:Entity ):Boolean
		{
			// if partEntity is null, then make sure that partArray contains the needed part
			if (partEntity == null)
			{
				trace("Error: Part entity not found. Make sure part is added to partArray.");
				return false;
			}
			
			// check empty or undefined
			var skinPart:SkinPart = partEntity.get( SkinPart );
			if( checkPartEmpty( skinPart ) )
			{
				return false;
			}
			
			if( !_ownedLook )	// item parts cannot be customized from scene npcs
			{
				if( skinPart.id == SkinUtils.ITEM )
				{
					return false;
				}
			}
			
			//if( metaPart )
			// check metadata
			var metaPart:MetaPart = partEntity.get( MetaPart );
			if( metaPart.currentData )
			{
				// check matching gender
				if( metaPart.currentData.gender )
				{
					if( metaPart.currentData.gender != _playerGender )	{ 
						return false; 
					}
				}
				
				// check costumizable if look is coming from scene, when look is from card costumizable is ignored
				if( !_ownedLook && !metaPart.currentData.costumizable )
				{
					return false; 
				}
			}
			else
			{
				trace("Error : Costumizer : metaPart for part " + skinPart.id +  " does not have current data.");
				return false;
			}
			
			return true;
		}
		
		private function checkPartEmpty( skinPart:SkinPart ):Boolean
		{
			if( skinPart.isEmpty || !DataUtils.isValidStringOrNumber(skinPart.value) )	
			{ 
				return true; 
			}
			// don't allow bare shirt
			if ((skinPart.id == "shirt") && (skinPart.value == "bare"))
			{
				return true;
			}
			return false;
		}
		
		private function addInteraction( partEntity:Entity, clickHandler:Function ):void
		{
			// NOTE :: loaded SWFs must contain a Symbol (MovieClip, Symbol), otherwise interaction won't work.
			// For more details review: http://www.flashandmath.com/howtos/swfs/
			var wrapper:Sprite = Display(partEntity.get(Display)).wrapDisplayObject();
			var interaction:Interaction = InteractionCreator.addToEntity( partEntity, _interactionArray, wrapper );
			if( !PlatformUtils.isMobileOS )
			{
				interaction.over.add( highlightPartOn );
				interaction.out.add( highlightPartOff );
			}
			
			interaction.click.add( clickHandler );
		}
		
		private function removeInteraction(partEntity:Entity):void
		{
			var interaction:Interaction = partEntity.get(Interaction);
			if(interaction)
			{
				interaction.removeAll();
			}
		}
		
		private function refreshInteraction( skinPart:SkinPart, partEntity:Entity ):void
		{
			if( partEntity.has(Interaction) )
			{
				// NOTE :: we use display container here, because we wrapper displayObject to create intitial Interaction
				InteractionCreator.refresh( partEntity, Display(partEntity.get(Display)).container );
				CharUtils.setAnim( _player, Pop );
			}
			else
			{
				// TODO :: Need to pass clickHandler
				//addInteraction( partEntity, 
			}
		}
		
		private function highlightPartOn( partEntity:Entity ):void
		{
			Display(partEntity.get(Display)).displayObject.filters = [new GlowFilter(0xFFFFFF, .9, 12, 12, 8, 1)];
		}
		
		private function highlightPartOff( partEntity:Entity ):void
		{
			Display(partEntity.get(Display)).displayObject.filters = null;
		}
		
		
		/**
		 * handler for when a player part is clicked
		 * @param partEntity
		 * @return 
		 */
		private function onPlayerPartClicked( partEntity:Entity ):void
		{
			var skinPart:SkinPart= partEntity.get(SkinPart);
			if( removePart( partEntity, skinPart ) )
			{
				// deselect corresponding part button
				// Currently if there isn't an NPC, then there are no slots
				// TODO :: should display player's parts when opened without npc look
				if( _costumeLook )
				{
					var partButton:Entity = getPartButtonById( skinPart.id );
					if( partButton )
					{
						Button(partButton.get(Button)).isSelected = false;
					}
				}
			}
		}
		
		/**
		 * handler for when a npc part is clicked
		 * @param partEntity
		 * @return 
		 */
		protected function onNpcPartClicked( partEntity:Entity ):void
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
		}
		
		/**
		 * Remove a part, parts can only be removed from the player dummy.
		 * Parts must not be permanent, are included in the basic parts set.
		 * @param partEntity - part Entity of player that is to be removed.
		 */
		private function removePart( partEntity:Entity, skinPart:SkinPart = null ):Boolean
		{
			if( !skinPart )	{ skinPart = partEntity.get(SkinPart); }
			
			// if pet, then restore standard eyes
			if ((_isPet) && (skinPart.id == "eyes"))
			{
				SkinUtils.setSkinPart( _player, "eyes", "eyes", false, Command.create( refreshInteraction, partEntity) );
				return true;
			}
			else if ( DataUtils.isValidStringOrNumber(skinPart.permanent) )
			{
				if( !skinPart.isPermanent() )
				{
					if( skinPart.permanent != SkinPart.EMPTY )
					{
						SkinUtils.setSkinPart( _player, skinPart.id, skinPart.permanent, false, Command.create( refreshInteraction, partEntity) );
						return true;
					}
				}
			}
			
			var partsArray:Vector.<String> = BASIC_PARTS;
			if (_isPet)
				partsArray = BASIC_PET_PARTS;
			if( partsArray.indexOf( skinPart.id ) == -1 )	//if not a basic part, remove
			{
				skinPart.remove(true);
				CharUtils.setAnim( _player, Pop );
				return true;
			}
			
			return false;
		}
		
		/**
		 * Add a part to the player dummy. 
		 * @param partEntity
		 * @param skinPart
		 */
		protected function addPart( partId:String, value:* ):void
		{
			var playerPartEntity:Entity = CharUtils.getPart( _player, partId );
			
			if( !playerPartEntity.has(Interaction) )	// if Interacton has not yet been added, add now, will refresh appropriately on laod complete
			{
				addInteraction( playerPartEntity, onPlayerPartClicked )
			}
			
			SkinUtils.setSkinPart( _player, partId, value, false, Command.create( refreshInteraction, playerPartEntity) );
		}
		
		public function get partsTrayButton():Entity { return _partsTrayButton; }
		public function get acceptButton():Entity { return _acceptButton; }
		public function get cancelButton():Entity { return _cancelButton; }
		
		private var _numLoadingChars:uint;
		private var _panelsVisible:Boolean;
		private var _charGroup:CharacterGroup;
		protected var _player:Entity;
		private var _model:Entity;
		private var _closetModels:Vector.<Entity> = new Vector.<Entity>();
		private var _playerGender:String;
		private var _costumeLook:LookData;
		private var _playerLook:LookData;
		protected var _ownedLook:Boolean;		// if look is pulled from card or closet, if so costumizable flag is ignored
		private var _skipNPCCheck:Boolean;
		private var _interactionArray:Array = [ InteractionCreator.OVER, InteractionCreator.OUT, InteractionCreator.DOWN, InteractionCreator.CLICK, InteractionCreator.RELEASE_OUT ];
		private var _partSlots:Vector.<Entity>;
		private var _partSlotDummies:Vector.<Entity>;
		private var _screenNpcNodes:Vector.<CharacterUpdateNode> = new Vector.<CharacterUpdateNode>();
		private var _clickableNPCs:Vector.<Entity> = new Vector.<Entity>();
		private var _dummyData:CharacterData;
		private var _isPet:Boolean = false;
		
		// buttons
		private var _cancelButton:Entity;
		private var _acceptButton:Entity;
		private var _targetButton:Entity;
		private var _partsTrayButton:Entity;
		//private var _closetButton:Entity;
		//private var _addClosetLookButton:Entity;
		
		// drawers
		private var _topPanel:UIDrawer;
		private var _leftPanel:UIDrawer;
		private var _rightPanel:UIDrawer;
		private var _partsPanel:UIDrawer;
		//private var _closetPanel:UIDrawer;
		
		private const PART_BTN_BUFFER:int = 10;
		private const PART_BTN_ASSET:String = "part_btn.swf";
		// parts you can't delete from character
		private const BASIC_PARTS:Vector.<String> = new <String>[ CharUtils.HAIR, CharUtils.SHIRT_PART, CharUtils.PANTS_PART, CharUtils.MOUTH_PART ];
		// parts you can't delete from pet
		private const BASIC_PET_PARTS:Vector.<String> = new <String>[ CharUtils.MOUTH_PART, CharUtils.MARKS_PART ];
		// character parts you can add
		private const COSTUME_PARTS:Vector.<String> = new <String>[ 	
			CharUtils.PACK, CharUtils.HAIR, CharUtils.ITEM, 
			CharUtils.SHIRT_PART, CharUtils.OVERSHIRT_PART, 
			CharUtils.PANTS_PART, CharUtils.OVERPANTS_PART, 															
			CharUtils.MARKS_PART, CharUtils.FACIAL_PART, 
			CharUtils.MOUTH_PART ];
		// pet parts you can add
		private const PET_PARTS:Vector.<String> = new <String>[CharUtils.FACIAL_PART, CharUtils.EYES_PART, CharUtils.OVERBODY_PART, CharUtils.HAT_PART];
		
		/**
		 * These values determine the offset for loaded characters in the part tray. For example, _costumeParts[1] (hair)
		 * should center the character so the hair is seen, so _partTrayOffsets[1], should move the character to just
		 * show the hair.
		 */
		private const _partTrayOffsets:Vector.<Point> = new <Point>[
			new Point(10, 50), new Point(-10, 130), new Point(-10, 30),
			new Point(5, 50), new Point(5, 50),
			new Point(5, 25), new Point(5, 25),
			new Point(-10, 95), new Point(-10, 125),
			new Point(-10, 95)];
		
		//private function get closetHasLooks():Boolean { return false; }
		//private function get canClickAnNPC():Boolean { return _clickableNPCs && _clickableNPCs.length > 0; }
		
		private const CHAR_SCALE:Number = 1.4;
		private const PET_SCALE:Number = 6.0;
		private const MANNEQUIN_SCALE:Number = .5;
		public const PLAYER:String = "playerDummy";
		public const MODEL:String = "modelDummy";
		public const TRAY:String = "trayDummy";
		
		public var onNPCSelected:Signal;
		public var onNPCPartSelected:Signal;
		public var onPartTraySelected:Signal;
		public var allCharsLoaded:Signal;
		
		public static const GROUP_ID:String				= "costumizer";
		// tracking
		public static const COSTUMIZER_OPENED:String	= 'CostumizerOpened';
		public static const COSTUME_ACCEPT:String		= 'CostumeChanged';
		
		// messaging
		public static const INITIAL_PROMPT:String		= 'SELECT A CHARACTER FROM YOUR CLOSET.';
		public static const PROMPT_CONJUNCTION:String	= '\nOR\n';
		public static const NPC_PROMPT:String			= 'TARGET A CHARACTER FROM THE SCENE.';
		public static const NO_COSTUMES_PROMPT:String	= 'EITHER PUT SOMETHING INTO YOUR CLOSET OR FIND A POPTROPICAN';
		public static const SELECT_NPC:String			= 'selectCharacter';
		
		private const CLOSET_FULL_MESSAGE:String = "Your closet already has 30 looks. A look must be deleted before adding another.";
		private const SAVE_FOR_CLOSET:String = "Save your game to save a look in your very own costume closet.";
		private const CLOSET_ERROR:String = "Could not access your closet looks, please try again later.";
	}
}