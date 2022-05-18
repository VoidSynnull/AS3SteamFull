package game.components.ui
{	
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.data.scene.characterDialog.DialogData;
	
	import org.osflash.signals.Signal;
	
	public class WordBalloon extends Component
	{
		public var cameraLimits:Rectangle;
		public var lifespan:Number;     			// length of time to display before fade out.
		public var answer:DialogData; 				// dialog data for a response
		public var answerTarget:Entity; 			// The entity answering a question.
		public var dialogData:DialogData;			// Data associated with this line of dialog.
		public var removed:Signal;   				// dispatched before this is removed from the game.  Sends along it's DialogData as a payload.
		public var speak:Boolean;    				// Should the parent entity speak when this word balloon is created?
		public var started:Boolean = false;			// flag determining is word balloon has started
		public var suppressEventTrigger:Boolean; 	// set to 'true' if a word balloon is being cancelled rather than chosen as a question response or a reply.
		
		override public function destroy():void
		{
			if( removed != null )	{ removed.removeAll(); }
			answerTarget = null;
			
			super.destroy();
		}
		
	}
}