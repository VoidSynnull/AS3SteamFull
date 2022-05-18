package game.scenes.examples.signalExample{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.examples.signalExample.components.Shadow;
	import game.scenes.examples.signalExample.systems.ShadowSystem;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class SignalExample extends PlatformerGameScene
	{
		private var timesLooped:Number = 0;
		
		public function SignalExample()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/signalExample/";
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			/**
			 * The function "handleEventTriggered" gets added to a Signal within ShellApi that handles events.
			 * Talking to the NPC triggers this event dispatch.
			 */
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			/**
			 * The ShadowSystem is a simple example of how to manipulate the scene using Signals from within
			 * a system.
			 * 
			 * A Shadow component gets added to the player entity. This Shadow component takes a function that will
			 * receive a Boolean from the Signal within the component, along with an "inZone" Boolean and params
			 * for a Rectangle (x, y, width, height) that will define the zone. Depending where the player is,
			 * the Shadow's Signal will dispatch the inZone Boolean, which will change what's viewable on the screen.
			 * 
			 * If the player is inside the "room" (or zone) in the scene, the outside world will be unviewable.
			 * If the player leave the room, the inside will become unviewable, and the outside world will be seen.
			 */
			//Add the system
			this.addSystem(new ShadowSystem());
			//Add the component to the player entity
			this.player.add(new Shadow(castShadow, false, 1000, 450, 500, 250));
			
			//Initially set the shadow and npc2 to not visible
			this._hitContainer.getChildByName("shadow").visible = false;
			Display(this.getEntityById("npc2").get(Display)).visible = false;
			
			
			var npc:Entity = this.getEntityById("npc1");
			this.setRandomSkin(npc);
		}
		
		private function setRandomSkin(npc:Entity):void
		{
			SkinUtils.setRandomSkin(npc);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(this.setRandomSkin, npc)));
		}
		
		private function castShadow(inZone:Boolean):void
		{
			//Things affected by shadowing
			var shadow:MovieClip = this._hitContainer.getChildByName("shadow") as MovieClip;
			var houseFront:MovieClip = this._hitContainer.getChildByName("houseFront") as MovieClip;
			var npc1:Display = Display(this.getEntityById("npc1").get(Display));
			var npc2:Display = Display(this.getEntityById("npc2").get(Display));
			
			/**
			 * Depending on where the player is in comparison to the zone, the ShadowSystem
			 * will dispatch a Boolean to say whether or not things are being shadowed.
			 * 
			 * True will only show what's visible in the house.
			 * False will show the outside world.
			 */
			if(inZone)
			{
				shadow.visible = true;
				houseFront.visible = false;
				npc1.visible = false;
				npc2.visible = true;
			}
			else
			{
				shadow.visible = false;
				houseFront.visible = true;
				npc1.visible = true;
				npc2.visible = false;
			}
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			/**
			 * The event triggered by the NPC is named "signalPopup" in npcs.xml.
			 * Once triggered, the popup will be initialized.
			 */
			if(event == "signalPopup")
			{
				showPopup();
			}
		}
		
		private function showPopup():void
		{
			/**
			 * This popup has several Signals within it that you can add functions to.
			 * Since the scene has no update function, changing the scene from the popup must be done with Signals.
			 * Each popup Signal gets a function (or functions) added to it that, when triggered from within the scene,
			 * will dispatch and execute all added functions. Notice that all of these Signal functions are "addOnce()";
			 * The button press in the popup only needs to be triggered once, then the functions are removed.
			 */
			var popup:SignalPopup = super.addChildGroup(new SignalPopup(super.overlayContainer)) as SignalPopup;
			popup.id = "signalPopup";
			
			/**
			 * The changeHair Signal dispatches an uint, so the "handleChangeHair" function should have an uint param.
			 * The uint is for the hair color.
			 */
			popup.changeHair.addOnce( handleChangeHair );
			
 			/**
			 * The teleport Signal only dispatches to all functions, so the "handleTelport" function should no params.
			 * Nothing from the popup is dispatched back to the scene. The function just executes when it is triggered.
			 */
			popup.teleport.addOnce( handleTeleport );
			
			/**
			 * The animation Signal dispatches a Class, so the "handleAnimation" function should have a Class param.
			 * An animation Class is dispatched back to the scene. The "handleAnimation" function also does more
			 * complex Signal work.
			 */
			popup.animation.addOnce( handleAnimation );
		}
		
		/**
		 * The "color" param is dispatched from withing the popup.
		 * Once the "Change Hair" button in the popup is pressed, this function will be executed.
		 */
		private function handleChangeHair(color:uint):void
		{
			//Set hair color
			SkinUtils.setSkinPart( player, SkinUtils.HAIR_COLOR, color, true );
		}
		
		/**
		 * No params are passed. It is a dispatch only Signal.
		 * Once the "Teleport" button in the popup is pressed, this function will be executed.
		 */
		private function handleTeleport():void
		{
			//Select a random "teleport" MovieClip and move the player there
			var clip:MovieClip = MovieClip(super._hitContainer.getChildByName("teleport" + Math.floor(Math.random() * 6)));
			
			var spatial:Spatial = this.getEntityById("player").get(Spatial);
			spatial.x = clip.x;
			spatial.y = clip.y;
		}
		
		/**
		 * The "animation" Class param is dispatched from withing the popup.
		 * Once the "Sleep" button in the popup is pressed, this function will be executed.
		 */
		private function handleAnimation(animation:Class):void
		{
			//Set the NPCs animation
			var npc:Entity = this.getEntityById("npc1");
			CharUtils.setAnim(npc, animation);
			
			/**
			 * An entity's Timeline also has Signals.
			 * When a label is reached, a Signal is dispatched that contains the label name, some of which can be
			 * found inside an animation's actionscript class. (i.e. Cabbage.as)
			 * 
			 * I also want to pass the NPC along with it, so that when the label is reached, I can manipulate the NPC.
			 * Usually, you would only pass a function to the Signal, but you can use the Command.create() util to
			 * append other params to the function to be passed along with the dispatch.
			 */
			Timeline(npc.get(Timeline)).labelReached.add(Command.create(handleReachedLabel, npc));
		}
		
		/**
		 * In this case, I'm incrementing a "timesLooped" variable to find out how many times the Signal for 
		 * the "loop" label has been triggered. Once it's done it a number of times, the NPC appended to the function
		 * will have its animation set back to Stand.
		 */
		private function handleReachedLabel(label:String, npc:Entity):void
		{
			if(npc == null) this.shellApi.log("NULL");
			if(label == "loop")
			{
				this.shellApi.log("Times Looped: " + timesLooped);
				if(++timesLooped > 4 )
				{
					CharUtils.setAnim(npc, Stand);
					Timeline(npc.get(Timeline)).labelReached.removeAll();
					timesLooped = 0;
					this.shellApi.log("Times Looped: " + timesLooped);
				}
			}
		}
	}
}