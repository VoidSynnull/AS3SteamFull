package game.scenes.carnival.mainStreet
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Door;
	import game.components.hit.Zone;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.game.GameEvent;
	import game.data.scene.DoorData;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.carnival.CarnivalEvents;
	import game.scenes.carnival.midwayDay.MidwayDay;
	import game.scenes.carnival.midwayEmpty.MidwayEmpty;
	import game.scenes.carnival.midwayEvening.MidwayEvening;
	import game.scenes.carnival.midwayNight.MidwayNight;
	import game.scenes.carnival.shared.popups.NewspaperPopup;
	import game.scenes.custom.AdMiniBillboard;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class MainStreet extends PlatformerGameScene
	{
		private var _events:CarnivalEvents;		
		private var gCampaignName:String = "MonsterCarnival";
		
		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/mainStreet/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addDoors(audioGroup:AudioGroup, data:XML = null):void
		{
			super.addDoors(audioGroup, data);
		
			var doorMidway:Entity;
			var doorData:DoorData;
			doorMidway = super.getEntityById("doorMidway");
			doorData = Door(doorMidway.get(Door)).data.connectingSceneDoors["exitRight"];
			
			if(this.shellApi.checkEvent(_events.SET_MORNING)){
				doorData.destinationScene = ClassUtils.getNameByObject(MidwayEmpty);
			}else if(this.shellApi.checkEvent(_events.SET_NIGHT)){				
				super.removeEntity(super.getEntityById("doorApothecary"), true);
				doorData.destinationScene = ClassUtils.getNameByObject(MidwayNight);
			}else if(this.shellApi.checkEvent(_events.SET_EVENING)){				
				doorData.destinationScene = ClassUtils.getNameByObject(MidwayEvening);
			}else{
				doorData.destinationScene = ClassUtils.getNameByObject(MidwayDay);
			}
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();			
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(965, 713),null,false);	

			_woman = super.getEntityById("woman");
			_man = super.getEntityById("man");
			_father = super.getEntityById("father");
			_junior = super.getEntityById("junior");
			_edgar = super.getEntityById("edgar");
			
			_doormidway = super.getEntityById("doorMidway");
			
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb1"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).smoke_mc, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).open_mc, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).sign_mc, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).apoth_mc, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).sundae_mc, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).icecream_mc, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).sign_night_mc, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).apoth_night_mc, this );
			
			//if day or empty
			if(!this.shellApi.checkEvent(_events.SET_NIGHT) && !this.shellApi.checkEvent(_events.SET_EVENING)){				
				super._hitContainer['sundae_mc'].visible = false;
				super._hitContainer['icecream_mc'].visible = false;
				
			}
			
			//if day, empty or evening
			if(!this.shellApi.checkEvent(_events.SET_NIGHT)){				
				super._hitContainer['sign_night_mc'].visible = false;
				super._hitContainer['apoth_night_mc'].visible = false;
				super._hitContainer['eyes1_mc'].visible = false;
				super._hitContainer['eyes2_mc'].visible = false;				
			//if night
			}else{
				super._hitContainer['sign_mc'].visible = false;
				super._hitContainer['apoth_mc'].visible = false;
				ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).apoth_btn, this, handleApothButtonClicked, null, null, ToolTipType.CLICK);
			}
					
			//if not day
			if(this.shellApi.checkEvent(_events.SET_MORNING) || this.shellApi.checkEvent(_events.SET_EVENING) || this.shellApi.checkEvent(_events.SET_NIGHT)){
				super.removeEntity( _woman );
				super.removeEntity( _man );
				super.removeEntity( _father );
				super.removeEntity( _junior );
				super.removeEntity( _edgar );
			//if day
			}else{			
				if(!this.shellApi.checkEvent(_events.SPOKE_EDGAR_CARNIVAL)){
					var edgarSpeakZone:Zone;
					_edgarSpeakZoneEntity = super.getEntityById( "edgarSpeakZone" );
					edgarSpeakZone = _edgarSpeakZoneEntity.get( Zone );
					edgarSpeakZone.pointHit = true;
					edgarSpeakZone.entered.addOnce(doEdgarSpeak);
					
					(this._doormidway.get( Display ) as Display ).visible = false;
					( this._doormidway.get( Sleep ) as Sleep ).sleeping = true;
				}else{
					super.removeEntity( _edgar );
				}
			}
			
			checkReplay();
			
			/*var rigAnim:RigAnimation = CharUtils.getRigAnim( _junior, 1 );
			if ( rigAnim == null ){
				var animationSlot:Entity = AnimationSlotCreator.create( _junior );
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			rigAnim.next = Read;
			rigAnim.addParts( 	CharUtils.HAND_FRONT );*/
			
			//track if non member is playing demo
			//REMOVE THIS WHEN EARLY ACCESS PERIOD ENDS
			if(!shellApi.profileManager.active.isMember && !shellApi.checkEvent(_events.STARTED_EA_DEMO)){
				shellApi.completeEvent(_events.STARTED_EA_DEMO);
				shellApi.track("Demo", "StartDemo", null, gCampaignName);
			}
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case "showPaperPop":
					var newspaperPop:NewspaperPopup = super.addChildGroup( new NewspaperPopup( super.overlayContainer )) as NewspaperPopup;
					break;
			}
			
		}
		
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb1"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		private function doEdgarSpeak(...args):void{
			lockControl();
			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;				

			actChain.addAction( new TalkAction( player, "whoAreYou" ) );
			actChain.addAction( new TalkAction( _edgar, "imEdgar" ) );
			actChain.addAction( new TalkAction( player, "youNervous" ) );
			actChain.addAction( new TalkAction( _edgar, "waitingCarnival" ) );
			actChain.addAction( new TalkAction( player, "howHelp" ) );
			actChain.addAction( new TalkAction( _edgar, "bigHelp" ) );
			actChain.addAction( new MoveAction( _edgar, new Point( 4900, 1280) ) );
			actChain.execute(this.finishEdgarSpeak);	

		}
		
		private function finishEdgarSpeak(...args):void{
			super.removeEntity( _edgar );
			super.shellApi.triggerEvent(_events.SPOKE_EDGAR_CARNIVAL, true)
			restoreControl();
			(this._doormidway.get( Display ) as Display ).visible = true;
			( this._doormidway.get( Sleep ) as Sleep ).sleeping = false;
		}
		
		private function handleApothButtonClicked(entity:Entity):void 
		{	
			Dialog(player.get(Dialog)).sayById("needInApothecary");
		}
		
		private function checkReplay():void
		{
			var lookAspectData:LookAspectData;
			var lookData:LookData
			
			if( !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.FLASHLIGHT ))
			{
				lookAspectData = SkinUtils.getLookAspect( player, SkinUtils.ITEM );
				if( lookAspectData )
				{
					lookData = new LookData();
					lookData.applyAspect( lookAspectData );
					
					if( lookAspectData.value == "mc_flashlight_normal" )
					{
						SkinUtils.removeLook( player, lookData );
					}
				}
			}
			
			if( !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.FLASHLIGHT_BLACK ))
			{
				lookAspectData= SkinUtils.getLookAspect( player, SkinUtils.ITEM );
				if( lookAspectData )
				{
					lookData = new LookData();
					lookData.applyAspect( lookAspectData );
					
					if( lookAspectData.value == "mc_flashlight_black" )
					{
						SkinUtils.removeLook( player, lookData );
					}
				}
			}
			
			if( !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.HAMMER ))
			{
				lookAspectData= SkinUtils.getLookAspect( player, SkinUtils.ITEM );
				if( lookAspectData )
				{
					lookData = new LookData();
					lookData.applyAspect( lookAspectData );
					
					if( lookAspectData.value == "mc_hammer" )
					{
						SkinUtils.removeLook( player, lookData );
					}
				}
			}
			
			if( !shellApi.checkEvent( GameEvent.GOT_ITEM + _events.HUMAN_FLY_MASK ))
			{
				lookAspectData = SkinUtils.getLookAspect( player, SkinUtils.FACIAL );
				if( lookAspectData )
				{
					lookData = new LookData();
					lookData.applyAspect( lookAspectData );
					
					if( lookAspectData.value == "mc_fly_mask" )
					{
						SkinUtils.removeLook( player, lookData );
					}
				}
			}
		}
		
		private function lockControl():void
		{
			MotionUtils.zeroMotion(super.player, "x");
			CharUtils.lockControls(super.player, true, true);
			SceneUtil.lockInput(this, true);
		}
		
		private function restoreControl():void
		{
			CharUtils.lockControls(super.player, false, false);
			MotionUtils.zeroMotion(super.player);
			SceneUtil.lockInput(this, false);
		}
		
		private var _woman:Entity;
		private var _man:Entity;
		private var _father:Entity;
		private var _junior:Entity;
		private var _edgar:Entity;
		private var _doormidway:Entity;
		private var _edgarSpeakZoneEntity:Entity;
	}	
	
}






