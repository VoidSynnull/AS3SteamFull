package game.scenes.poptropolis.coliseum.popups
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.creators.ui.ToolTipCreator;
	import game.data.ui.ToolTipType;
	import game.data.ui.TransitionData;
	import game.scenes.poptropolis.archery.Archery;
	import game.scenes.poptropolis.diving.Diving;
	import game.scenes.poptropolis.hurdles.Hurdles;
	import game.scenes.poptropolis.javelin.Javelin;
	import game.scenes.poptropolis.longJump.LongJump;
	import game.scenes.poptropolis.poleVault.PoleVault;
	import game.scenes.poptropolis.shotput.Shotput;
	import game.scenes.poptropolis.skiing.Skiing;
	import game.scenes.poptropolis.tripleJump.TripleJump;
	import game.scenes.poptropolis.volleyball.Volleyball;
	import game.scenes.poptropolis.weightLift.WeightLift;
	import game.ui.hud.HudPopBrowser;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.DisplayPositions;
	import game.util.EntityUtils;
	import game.util.TextUtils;
	
	public class EventPopup extends Popup
	{
		private var isTesting:Boolean = true;
		private var isMember:Boolean;
		private var gCampaignName:String = "PoptropolisPromo";
		
		private var indicator:MovieClip;
		
		private var _events:Vector.<String> = new <String> ["archery", "shotput"];	// events available as non-member during early access.
		private var _memberEvents:Vector.<String> = new <String> ["diving", "hurdles", "javelin", "long_jump", "pole_vault", "weight_lifting", "skiing", "triple_jump", "volleyball"];
		
		private var scenes:Dictionary = new Dictionary();
	
		public function EventPopup(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		// pre load setup
		public override function init(container:DisplayObjectContainer = null):void
		{
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.startPos = new Point( 0, super.shellApi.viewportHeight );
			super.transitionIn.endPos = new Point( 0, 0 );
			super.transitionIn.duration = .3;
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.transitionOut.duration = .2;
			super.darkenBackground = true;
			super.darkenAlpha = .6
			
			groupPrefix = "scenes/poptropolis/coliseum/";
			super.screenAsset = "eventPopup.swf";
			super.init(container);
			super.load();
		}		

		// all assets ready
		public override function loaded():void
		{
			super.loaded();
			
			this.centerWithinDimensions(this.screen.content);
			
			this.pinToEdgeAbsolute(this.screen.background, DisplayPositions.BOTTOM_LEFT, 0, 394);
			this.screen.background.width = this.shellApi.viewportWidth;
			//this.screen.background.height = this.shellApi.viewportHeight;
			
			super.loadCloseButton();
			
			//this.isMember = super.shellApi.profileManager.active.isMember;
			//setting to true now that everyone can play, 12/5/13 -Jordan
			this.isMember = true;
			
			this.refreshText();
			this.setupScenes();
			this.setupEvents();
			this.setupButtons();
			this.setupMembershipButton();
		}
		
		private function refreshText():void
		{
			TextUtils.refreshText( this.screen.content.select_tf, "GhostKid AOE" );
			var text:TextField = TextUtils.refreshText( this.screen.content.nonMemberBlock.message_tf, "CreativeBlock BB" );
			text.name = "message_tf";
			text.parent["message_tf"] = text;
			
			for(var i:int = 1; i <= 11; i++) TextUtils.refreshText( this.screen.content["event_tf_" + i], "Diogenes" );
		}
		
		private function setupScenes():void
		{
			//Setup each event name as a key to a corresponding scene Class.
			this.scenes["archery"] 			= Archery;
			this.scenes["diving"] 			= Diving;
			this.scenes["hurdles"] 			= Hurdles;
			this.scenes["javelin"] 			= Javelin;
			this.scenes["long_jump"] 		= LongJump;
			this.scenes["pole_vault"] 		= PoleVault;
			this.scenes["weight_lifting"] 	= WeightLift;
			this.scenes["shotput"] 			= Shotput;
			this.scenes["skiing"] 			= Skiing;
			this.scenes["triple_jump"] 		= TripleJump;
			this.scenes["volleyball"] 		= Volleyball;
		}
		
		private function setupEvents():void
		{
			/**
			 * If the player is a member or isTesting = true, push all of the member events into the list of events,
			 * which already includes the non-member Archery and Shotput events. If the player isn't a member or
			 * isTesting = false, dim/fade out all of the member events.
			 */
				// NOTE :: set to true for testing
			if(this.isMember || this.isTesting)
			{
				while(_memberEvents.length > 0)
					_events.push(_memberEvents.pop());
			}
			else
			{
				for each(var memberEvent:String in _memberEvents)
					this.screen.content[memberEvent].alpha = 0.3;
			}
			
			var events:Vector.<String> = this._events.concat(_memberEvents);
			for each(var event:String in events)
				this.screen.content[event + "_completed"].visible = false;
		}
		
		private function setupButtons():void
		{
			//Initially set the circular event indicator to not be visible.
			this.indicator = this.screen.content["indicator"];
			this.indicator.visible = false;
			
			var i:int;
				
			/**
			 * For each event that's been pushed to events, create a button. If an event has already been played,
			 * dim/fade out the event. This adds listener Functions for moving the indicator and loading the event's scene.
			 */
			for(i = 0; i < _events.length; i++)
				this.configureButton(_events[i], false);
			
			
			for(i = 0; i < _memberEvents.length; i++)
				this.configureButton(_memberEvents[i], true);
		}
		
		private function configureButton(event:String, showMembership:Boolean):void
		{
			if(this.shellApi.checkEvent(event + "_completed"))
			{
				this.screen.content[event].alpha = 0.3;
				this.screen.content[event + "_completed"].visible = true;
				return;
			}
			
			var button:Entity = EntityUtils.createSpatialEntity(this, this.screen.content[event]);
			button.add(new Id(event));
			
			var interaction:Interaction = InteractionCreator.addToEntity(button, ["over", "out", "down"]);
			interaction.over.add(Command.create(setIndicator, true));
			interaction.out.add(Command.create(setIndicator, false));
			
			if(showMembership)
			{
				interaction.over.add(Command.create(resizeMembershipButton, true));
				interaction.out.add(Command.create(resizeMembershipButton, false));
				Display(button.get(Display)).alpha = 0.3;
			}
			else interaction.down.add(loadScene);
			
			ToolTipCreator.addUIRollover(button, ToolTipType.CLICK);
		}
		
		private function resizeMembershipButton(entity:Entity, larger:Boolean):void
		{
			var spatial:Spatial = this.getEntityById("membership").get(Spatial);
			var message:DisplayObject = this.screen.content.nonMemberBlock.message_tf;
			
			if(larger)
			{
				spatial.scaleX = spatial.scaleY = 1.2;
				message.scaleX = message.scaleY = 1.04;
				
			}
			else
			{
				spatial.scaleX = spatial.scaleY = 1;
				message.scaleX = message.scaleY = 1;
			}
		}
		
		private function setupMembershipButton():void
		{
			if(this.isMember)
			{
				this.screen.content.nonMemberBlock.visible = false;
				return;
			}
			
			var button:Entity = EntityUtils.createSpatialEntity(this, this.screen.content.nonMemberBlock.buyMembership);
			button.add(new Id("membership"));
			
			var interaction:Interaction = InteractionCreator.addToEntity(button, ["down"]);
			interaction.down.add(clickMembershipButton);
			
			ToolTipCreator.addUIRollover(button, ToolTipType.CLICK);
		}
		
		private function setIndicator(entity:Entity, show:Boolean):void
		{
			if(show)
			{
				var spatial:Spatial = entity.get(Spatial);
				this.indicator.visible = true;
				this.indicator.x = spatial.x;
				this.indicator.y = spatial.y;
			}
			else this.indicator.visible = false;
		}
		
		private function loadScene(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ui_button_click.mp3");
			this.shellApi.loadScene(this.scenes[entity.get(Id).id]);
			
			_events = null;
			this.scenes = null;
		}
		
		private function clickMembershipButton(entity:Entity):void
		{
			super.shellApi.track("ClickToSponsor", "Bonus Quest Block", null, gCampaignName);
			HudPopBrowser.buyMembership(super.shellApi);
		}
		
		public override function destroy():void
		{
			super.destroy();
		}
	}
}