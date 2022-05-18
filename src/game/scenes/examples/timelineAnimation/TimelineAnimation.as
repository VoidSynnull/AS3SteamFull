package game.scenes.examples.timelineAnimation{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.timeline.TimelineMaster;
	import game.scene.template.PlatformerGameScene;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.systems.timeline.TimelineVariableSystem;
	import game.util.TimelineUtils;
	
	public class TimelineAnimation extends PlatformerGameScene
	{
		public function TimelineAnimation()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/timelineAnimation/";
			
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			super.addSystem( new TimelineControlSystem() );
			super.addSystem( new TimelineClipSystem() );
			super.addSystem( new TimelineVariableSystem() );
			
			timelineAnimationExample();
			variablePlaybackSpeedExample();
		}
		
		private function timelineAnimationExample():void
		{
			
			/** Due to limitations on code within swf by iOS 
			 * we can no longer rely on Action Script with timelines.
			 * But never fear, solutions are here.
			 * 
			 * To solve this problem, we move the action script into the labels.
			 * This techniques allows us to:
				 * Side step the action script limitation of mobile
				 * Update timeline progression using the frameworks single update loop
				 * Use for variable framerates, inherited pausing, and possibly other fun stuff.
			
			 * So how does it work?  Let's look at an example.
			 */
			
			/**
			 * First let's get a movieclip to work with.
			 * A MovieClip with instance name "ball1" has been included within the interactive layer
			 */
			
			var testClip:MovieClip = super._hitContainer["ball1"] as MovieClip;
			
			/**
			 * Now let's look at the asset itself, whihc in in the laers.fla within ht einteractive folder
			 * Open it up in the IDE and let's take a gander within the ball_anim folder at converted.
			 * In the layer actions (which has been commented out) we see our standard timeline stuff, stops, goToAndPlays, labels, etc.
			 * Below that is our labels layer where you'll see that the action script has been moved into the labels.
			 * On the frames where there was a label and actionscript, the actionscript has been moved into the label alongside the previos label name
			 * and that they are separated by a comma with no space.
			 * For example let's look at frame #'s label:
				 * 
				 * reachedEnd,stop()
				 * 
			 * Let's look at frame #'s label next:
				 * 
				 * reachedLoop,gotoAndPlay(loop)
				 * 
			 * In both we've just moved the AS into the label with minor adjustments.
			 * Those adjustments are:
				 * Semicolors have been removed from the AS
				 * Quotes have been removed from label names with gotoAndPlay & gotoAndStop
			 * These changes are really just for usability and ease of xml use
			 */
			
			/**
			 * A jsfl script has been created that automates this actionscript to label conversion process.
			 * Refer to this provided document for how to setup and use the script:
				 * 
				 * projects/poptropica2/docs/guides/PENDING
				 * 
			 */
			
			/**
			 * Let's get back to our code now that we've seen what in our exampleClip.
			 * 
			 * So how do we turn the AS that was moved into labels back into code?
			 * Well we do this by converting the movieCLip into an Entity with the necessary components.
			 * We'll go through this process step by step.
			 */
			
			// First let's make a new entity.
			 
			 var myEntity:Entity = new Entity();
			 this.addEntity( myEntity );
			 
			// Next we add the components necessary for it to be animated by its timeline.
			
			/**
			 * Timeline component does what you'd expect, it gives the entity its own timeline.
			 * The Timeline component also stores the information about a timeline animation.
			 * We'll look at how it gets and stores that data later
			 */
			
			 var timeline:Timeline = new Timeline();
			 myEntity.add( timeline );
			  
			/**
			 * TimelineMaster component acts as a flag.
			 * It notifies that this entity is the one that should process the Timeline,
			 * in this way Timeline and MasterTimeline components work as a pair.
			 * We do this because in some cases we may want to share a Timeline component
			 * with other entities, so that they can refer to the Timeline's frame, state, etc.
			 * But we don't want this Timeline to be updated by multiple entities,
			 * that would mean that a Timeline could increment its frame multiple times in a single update,
			 * causing it to go from frame 2 to 6 for example if it was shared with 3 entities.
			 * 
			 * This is where TimelineMaster comes in as only entities with both Timeline and TimelineMaster components
			 * are picked up by the system that updates the Timeline component.
			 * Any Entity with just a Timeline component and no MasterTimeline will not update the Timeline.
			 */
			 
			 var timelineMaster:TimelineMaster = new TimelineMaster();
			 myEntity.add( timelineMaster );
			 
			/**
			 * The TimelineClip is what ends up connecting you Timeline to your Display.
			 * Since Timeline components can be used in different circumstances, 
			 * it is not tied to a MovieClip, it's only concern updating its current frame.
			 * To actually apply the information a Timeline component provides 
			 * we use a different that requires a Timeline, Display, & TimelineClip component.
			 * The TimelineClip point directly to the instance that we want to apply the timeline to.
			 * Since that instance may actualy be nested with the Display component's displayObject
			 * we rely on TimelineClip to maintain a direct reference to the clip we want to animate.
			 */
			
			 var timelineClip:TimelineClip = new TimelineClip();
			 timelineClip.mc = testClip;
			 myEntity.add( timelineClip );
			 
			/**
			 * What we want to animate is the MovieClip on the stage, so we point to that MovieClip by instanceName.
			 * This nesting within a swf is common practice as we do not want to animate directly on the stage.
			 * 
			 * We also cast testClip to a MovieClip, this prevents compiler errors associated with
			 * Using dot notation with a DisplayObjetcContainer.  
			 * Casting may not always be necessary, but it tends to prevent bugs that are hard to track.
			 */ 

			/**
			 * OK!  Almost there, I promise.
			 * 
			 * Just a couple more things to do.
			 * First we need to convert the labels within the swf into something the Timeline can process.
			 * This conversion can get a little nitty gritty, so we use a helper method from on eof our utility classes.
			 */
			
			 TimelineUtils.parseMovieClip( timeline, timelineClip.mc );
			 
			/**
			 * So we pass the Timeline and the MovieClip that contains the timeline we want to convert.
			 * The conversion process basically runs through the movieclip checking each frame for a label,
			 * parses the label's String into discreet units using the comma as a divider, 
			 * and then determine if the String is actually a timeline command ( stop, play, gotoAndPlay, etc )
			 * or if it is just a label name.
			 * It then pushes this information into the Timeline component.
			 */
			
			/**
			 * Since the systems will be will be controlling the Moveiclips progression from here on out
			 * let's make sure the MovieClip starts at it's first frame and stays there until we tell it differently.
			 */
			
			 timelineClip.mc.gotoAndStop(1);
			 
			/**
			 * We also want to make sure to reset the Timeline component. 
			 * This just sets playing to true, and resets the frame index
			 */
			
			 timeline.reset();
			 
			/**
			 * You did it!
			 * You've made an Entity that makes your MovieClip function as you'd expect.
			 * A lot of steps though, right?
			 * Never fear, there is a much faster way, but now you know how everything works.
			 * Let's grab the next movieclip that has been included within the interactive layer.
			 */

			var testClip2:MovieClip = super._hitContainer["ball2"] as MovieClip;
			var myEasyEntity:Entity = TimelineUtils.convertClip( testClip2, this );

			/**
			 * Boom, you're done.  This will return an Entity will all of the necessray components and conversion.
			 * If you already have a entity you want to use, you can just pass it as a param:
				 * 
				 * TimelineUtils.convertClip( testClip, myPremadeEntity );
				 * 
			 */

			/**
			 * This example just converts a single MovieClip.
			 * If you to convert a MovieClip and all of it's children, then you would use this method:
				 * 
				 * TimelineUtils.convertAllClips( testClip );
				 * 
			 * This will convert the MovieClip passed and any MoveClips within it
			 * that have timelines with length greater than 1.  
			 * It also creates Parent chaining, so pasuing and sleep is passed down.
			 */
		}
		
		
		private function variablePlaybackSpeedExample():void
		{
			// By default aniamtions will play at 30 frames per second, but in some csases you may want more control over playback speed.
			// For this there is a TimelineVariableSystem, that allows you to specify the framerate.
			
			var ball:MovieClip;
			
			// set a ball to animate twice as fast, but this ball's timeline has already been animated in 2s, so it should playback normally
			ball = super._hitContainer["ball3"] as MovieClip;
			var fewerFrames:Entity = TimelineUtils.convertClip( ball, this, null, null, true, 64 );	// see set the framerate to 15, essentially holding each frame for 2
			
			ball = super._hitContainer["ball4"] as MovieClip;
			var standardFrames:Entity = TimelineUtils.convertClip( ball, this, null, null, true, 32 );
			
			// set a ball to animate twice as fast
			ball = super._hitContainer["ball5"] as MovieClip;
			var animateOnHalves:Entity = TimelineUtils.convertClip( ball, this, null, null, true, 16 );	// see set the framerate to 15, essentially at animating at double speed
			
			// set a ball to animate twice as slow
			ball = super._hitContainer["ball6"] as MovieClip;
			var animateOnTwos:Entity = TimelineUtils.convertClip( ball, this, null, null, true, 64 );	// see set the framerate to 60, essentially holding each frame for 2
			
			
			
		}
	}
}