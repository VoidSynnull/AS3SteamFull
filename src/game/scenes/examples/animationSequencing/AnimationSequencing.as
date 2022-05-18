package game.scenes.examples.animationSequencing{
	import flash.display.DisplayObjectContainer;
	
	import game.scene.template.PlatformerGameScene;
	
	public class AnimationSequencing extends PlatformerGameScene
	{
		public function AnimationSequencing()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/animationSequencing/";
			
			super.init(container);
		}

		override public function loaded():void
		{
			super.loaded();
			
			/**
			 * Introduction to Animation Sequences via XML
			 * 
			 * Npcs can be given animation sequences directly through xml.
			 * Open the the npc.xml for this scene to see how this is working:
				 * 
				 * bin/data/scenes/examples/characterAnimation/npcs.xml
			 */
			
			/**
			 * Example 1 : Creating a Sequence
			 * 
			 * Let's look at the first npc, redHead:
				 
			 	<npc id="redHead">
					<animations loop="true" random="false">
						<animation>game.data.animation.entity.character.Cry</animation>
						<animation>game.data.animation.entity.character.Grief</animation>
					</animations>
			 * 
			 * At the top of the npc's xml you should see the animation sequence
			 * it is defined within the <animations> tags and has a coiuple of attributes:
				 * the loop attributes determines if the sequence will loop.
				 * the random attributes the sequence order, if true it will be random.
			 * The <animation> tags specify animations that this sequence will play.
			 * So if we look at redhead sequence attributes we know that the sequence will:
				 * loop, continually cycling through the animations  
				 * go in order, since random is set to false, meaning the animations will play in the order listed
			 * So we should observe redHead first crying and then grieving, then crying again.
			 */
			
			/**
			 * WARNING :: The animations point to actual classes, and since they are being defined 
			 * in xml they may not be declared within the frameowrk, so we will need to add
			 * them to the DynamicallyLoadedClassManifest.as.  
			 * Yes, it's a hassle, hopefully we'll have a better fix soon.
			 */
			 
			/**
			 * Example 2 : Animations are Different, Some Loop
			 * 
			 * The type of animation you choose will effect the sequence, since not all animations are the same.
			 * To highlight this let's look at our next npc, orangeHead:
			 * 
			 	<npc id="orangeHead">
					<animations loop="true" random="false">
						<animation>game.data.animation.entity.character.Cry</animation>
						<animation>game.data.animation.entity.character.Cabbage</animation>
					</animations>
			 * 
			 * This guy is the same as redHead, except instead of playing the Grief animation after Cry
			 * this npc will play the Cabbage animation.
			 * So when the Cabbage animation is done the Cry animation should begin.
			 * But this isn't happening, if you watch he'll Cry and then Cabbage, but never stop Cabbaging.
			 * This is because the Cabbage animation is a looping animation, and doesn't have an 'end'.
			 * Since Cabbage loops it will never call 'end', and the sequence is never told to move to the next animation. 
			 * So in this instance once the character starts the Cabbage animation he will just keep on cabbaging
			 */
			  
			/**
			 * Example 3 : Adding Duration to Animations
			 * 
			 * So let's look at greenHead to see how to solve orangeHead's problem:
			 * 
			 	<npc id="greenHead">
					<animations loop="true" random="false">
						<animation>game.data.animation.entity.character.Cry</animation>
						<animation duration="60">game.data.animation.entity.character.Cabbage</animation>
					</animations>
			 * 
			 * One part of the problem is knowing that the Cabbage animation loops.
			 * There are a number of ways to figure this out:
				 * You can test the animation and observe that it loops
				 * You can refer to the animation.fla and find the cabbage clip
				 * You can look at the bin/entity/character/animation/human/cabbage.xml 
			 * The last option involves knowing about how the animations as parse as xml,
			 * which will be covered elsewhere, but for now know that you can look at xml
			 * to see how the animation's timeline will function.
			 * 
			 * Every animation is different, so getting a sense of what each one does is
			 * will help you predict it's behavior.  In the future we could have documentation 
			 * with mor einformation about each animaiton.
			 * 
			 * The real problem is being able to 'end' a looping animation. 
			 * For this we can use the animation's duration attribute.
			 * You'll see in greenHead's cabbage animation that we've added
			 * a duration attribute and given it a value of 60.
			 * By setting the animation's duration attribute we are essentially giving it a time limit.
			 * The duration value is in frames.
			 * So in this example Cabbage will play for 60 frames, after which it will 'end'. 
			 * Once Cabbage ends the sequence will continue to the next animation, which is Cry.
			 * Viola, we have our Mr.Greehead displaying some very bipolar behavior.
			 * 
			 * Durations can be applied to any animation, whether it loops or not.
			 * We'll see another application in the further examples.
			 */
			
			/**
			 * Example 4 : Animation Defaults
			 * 
			 * By default npcs do not have animation sequences, but they are still playing an animation.
			 * This animation is usually Stand, but could also be Fall, Walk, Climb, really any animation that 
			 * is driven by the npc's interaction with it's environment.
			 * This is because unless an animation is specifically applied the characters will to 'auto'.
			 * When in 'auto' the characters animation is driven by systems that take into acount environment, control, speed, etc.
			 * 
			 * So when you don't specify an animation sequence the character defaults to auto.
			 * So all of these xml setups will produce the same effect, the npc being driven by auto:
				 
				<npc id="blueHead">
				<skin>...
				
				<npc id="blueHead">
					<animations loop="true">
					</animations>
				<skin>...
				
				<npc id="blueHead">
					<animations loop="true">
						<animation></animation>
					</animations>
				<skin>...
				
			 * Notice the last example, where we specify an animation, but don't include an animation class.
			 * If no animation class is reads that as the absence of an animation, and if there is no animation
			 * then auto takes over.
			 * 
			 * Let's look at the last example to see how we can use auto within a sequence.
			 */
				
			/**
			 * Example 5 : Using Auto Within a Sequence
			 * 
			 * Let' look at purpleHead's xml:
				 
				<npc id="purpleHead">
					<animations loop="true" random="true">
						<animation>game.data.animation.entity.character.Cry</animation>
						<animation>game.data.animation.entity.character.Grief</animation>
						<animation duration="80"></animation>
					</animations>
					
			 * This time we have set random to true, so when the sequence is ready for its next animation
			 * that animation will be selected randomly from the list.
			 * 
			 * We've used Cry and Grief again which don't do anything special.
			 * We've also include an 'empty' animation and given it a duration.
			 * This empty animation will trigger 'auto', and since auto does not have an 'end' we set a duration.
			 * So when the sequence selects the empty animation, auto will trigger and remain for 80 frames.
			 * In this circumstance an npc in 'auto' is just going to stand there, playing the Stand animation,
			 * but when we have wandering implemented the npc could move to different location, 
			 * letting 'auto' determine its animations.
			 */
		}
	}
}