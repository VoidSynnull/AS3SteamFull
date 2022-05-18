package engine.util
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	
	import engine.ShellApi;
	import engine.creators.InteractionCreator;
	
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	
	import org.osflash.signals.natives.NativeSignal;

	public class DevTools
	{
		public function DevTools(container:DisplayObjectContainer)
		{
			_container = container;
		}
		
		public function init():void
		{
			_keyPress = InteractionCreator.create(_stage, InteractionCreator.KEY_UP);
			_keyPress.add(handleKeyUp);
			this.console = new Console(_container);
			this.console.triggerCommand.add(handleTriggerCommand);
			_shellApi.injector.injectInto(this.console);
			
			if(ProxyUtils.isTestServer(_stage.loaderInfo.url))
			{
				if(!PlatformUtils.isMobileOS || AppConfig.debug)
				{
					this.console.unlockConsole();
				}
			}
		}
		
		public function showConsole():void
		{
			this.console.show();
		}
		
		public function hideConsole():void
		{
			this.console.hide();
		}
		
		public function toggleConsole():void
		{
			this.console.toggle();
		}
		
		private function showFPS():void
		{
			_performanceMonitor = new PerformanceMonitor();			
			_container.addChild(_performanceMonitor);
			
			_performanceMonitorClicked = InteractionCreator.create(_performanceMonitor, InteractionCreator.DOWN);
			_performanceMonitorClicked.add(performanceMonitorClicked);
			
			hideConsole();
		}
		
		private function hideFPS():void
		{		
			_performanceMonitor.destroy();
			_container.removeChild(_performanceMonitor);
			_performanceMonitorClicked.removeAll();
			_performanceMonitor = null;
			_performanceMonitorClicked = null;
		}
		
		private function performanceMonitorClicked(event:Event):void
		{
			if (_performanceMonitor.scaleX == 1)
			{
				_performanceMonitor.scaleX = _performanceMonitor.scaleY = 2;
			} 
			else 
			{
				_performanceMonitor.scaleX = _performanceMonitor.scaleY = 1;
			}
		}
		
		private function handleKeyUp(event:KeyboardEvent):void
		{						
			// _container.alpha -= .3
			switch(event.keyCode)
			{
				// "~"
				case 192 :
					//this.console.toggle();
				break;
				
				// enter
				case Keyboard.ENTER :
					if(this.console.active)
					{
						this.console.processCommands();
					}
				break;
				
				//"up arrow"
				case Keyboard.UP :
					if(this.console.active)
					{
						this.console.shiftCommandHistoryIndex(1);
					}
				break;
				
				//"down arrow"
				case Keyboard.DOWN :
					if(this.console.active)
					{
						this.console.shiftCommandHistoryIndex(-1);
					}
				break;
			}
		}
		
		private function handleTriggerCommand(command:Array):void
		{
			switch(command[0])
			{
				case "fps" :
					if(_performanceMonitor == null)
					{
						showFPS();
					}
					else
					{
						hideFPS();
					}
				break;
				
				case "hide" :
					this.console.hide();
				break;
			}
		}
		
		public var console:Console;
		private var _performanceMonitor:PerformanceMonitor;
		private var _performanceMonitorClicked:NativeSignal;
		private var _container:DisplayObjectContainer;
		private var _keyPress:NativeSignal;
		
		[Inject]
		public var _shellApi:ShellApi;
		[Inject]
		public var _stage:Stage;
	}
}