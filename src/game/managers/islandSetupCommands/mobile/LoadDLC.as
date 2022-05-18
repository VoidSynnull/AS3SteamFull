package game.managers.islandSetupCommands.mobile
{
	import com.poptropica.AppConfig;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import engine.ShellApi;
	import engine.command.CommandStep;
	
	import game.data.dlc.DLCContentData;
	import game.managers.DLCManager;
	
	/**
	 * LoadDLCContent
	 * 
	 * Loads the content for a new island via the DLCManager.  Sends the user to the map if content needs to be loaded from the
	 *  server.  In that case the loadScene sequence will end here. 
	 */
	
	public class LoadDLC extends CommandStep
	{
		/**
		 * Start command to get ad content for island
		 * @param island - island being opened
		 * @param shellApi
		 * @param gameData
		 * @param newIsland - flag determining if new, essentailly if the next island is not equal to current island
		 * 
		 */
		public function LoadDLC( shellApi:ShellApi, island:String, onFailure:Function = null )
		{
			super();
			
			_shellApi = shellApi;
			_island = island;
			_onFailure = onFailure;
			
		}
		
		override public function execute():void
		{
			// TODO :: We should determine what type of UI is required - bard
			_skipSecondaryContent = false;	// reset for each island load
			_contentTimer = null;			// clear out old timer
			loadContent();
		}
		
		private function loadContent( ...args ):void
		{
			clearContentTimer();
			
			var dlcManager:DLCManager = _shellApi.getManager(DLCManager) as DLCManager;
			if( dlcManager.queueTotal > 0 )
			{
				// set completion handler
				// TODO :: Probably want to allow for download display at this point\				
				// TODO :: What is loading to a custom island though? - bard
				// if we are loading into a standard island (not the 'custom' island) then we probably want a time out for ad content
				// if we are loading into a custom island then we wnt to display DLC UI (if we actually need to load content)
				_currentContent = dlcManager.getNextInQueue();
				if( _currentContent )
				{
					if( _currentContent.type == DLCManager.TYPE_SECONDARY_CONTENT )
					{
						// for secondary content (example. in island ad content) we allow a timer duration for download, if time is surpassed ignore content and all other secondary content from that point
						if( !_skipSecondaryContent )
						{
							setContentTimer( _currentContent );
							dlcManager.startNextInQueue( this.loadContent, null, onLoadError, null );
						}
						else
						{
							dlcManager.removeFromQueue( _currentContent );
							loadContent();
						}
					}
					else if (_currentContent.type == DLCManager.TYPE_PRIMARY_CONTENT )
					{
						// QUESTION :: Do we want/need any sort of timeout here?  Currently primary content wouldn't really be loading here or decompressing here - bard
						_currentContent = dlcManager.startNextInQueue( this.loadContent, null, onLoadError, null );
					}
					else
					{
						// NOTE :: Not sure what this case would be as of yet
						_currentContent = dlcManager.startNextInQueue( this.loadContent, null, onLoadError, null );
					}
				}
				else
				{
					trace( this," :: WARNING : loadContent : no DLC was found, which is odd.");
					this.complete();
				}
			}
			else
			{
				_currentContent = null;
				this.complete();
			}
		}
		
		/**
		 * Call if there is an error with the content, or it has taken too long to process
		 * @param dlcData
		 * @param args
		 */
		private function onLoadError( dlcData:DLCContentData = null, ...args ):void
		{
			clearContentTimer();
			
			// TODO :: How errors are handled also has to do with what island you are trying to load to.
			// if loading into a standard island, we can continue if we experience an ad file failure can 
			// but if loading to a custom island, failure to load files should abort process
			if( dlcData )
			{
				trace( "Error :: LoadDLC : DLC failed to load & install for content: " + dlcData.contentId + " of type: " + dlcData.type + " isValid: " + dlcData.isValid);
				if( dlcData.type == DLCManager.TYPE_SECONDARY_CONTENT )
				{
					// if secondary content (in island ads) fail or take too ling to load, we can continue with loading the rest of other content
					this.loadContent();
				}
				else if (dlcData.type == DLCManager.TYPE_PRIMARY_CONTENT )
				{
					// cancel all current downloads clearing queue, and end process					
					(_shellApi.getManager(DLCManager) as DLCManager).cancelAllContentDownloads();
					_currentContent = null;
					// _onFailure should handle what happens if this process fails 
					if( _onFailure )	{ _onFailure(); }
					_contentTimer = null;
					super.completeAll();
				}
			}
			else
			{
				trace( this," :: Error :: DLC failed to load & install, data for content not found.");
				// if DLCContentData not found then soldier on
				this.loadContent();
			}
		}
		
		override public function complete( increment:int = 1 ):void
		{
			_onFailure = null;
			if( _contentTimer )	{ _contentTimer.stop(); }
			_contentTimer = null;
			
			super.complete( increment);
		}
		
		//////////////////////////////// CONENT TIMEOUT ////////////////////////////////
		
		/**
		 * Start timer for content 
		 * @param dlcData
		 */
		private function setContentTimer( dlcData:DLCContentData ):void
		{
			if( _contentTimer == null )
			{
				_contentTimer = new Timer(AppConfig.timeLimitForSecondaryContent, 1);
			}
			
			_contentTimer.addEventListener(TimerEvent.TIMER_COMPLETE, contentTimerComplete );
			_contentTimer.reset();
			_contentTimer.start();
		}
		
		/**
		 * Called when content timer is up, cancels content download
		 * @param event
		 */
		private function contentTimerComplete(event : TimerEvent) : void
		{
			clearContentTimer();
			if( _currentContent )
			{
				trace( this," :: contentTimerComplete : Content time limit reached, took too long to retreive content: " + _currentContent.contentId + " will skip secondary content for this island load.");
				(_shellApi.getManager(DLCManager) as DLCManager).cancelContentDownload( "", _currentContent, false );
				onLoadError( _currentContent );
			}
			else
			{
				trace( this," :: Error :: contentTimerComplete : timer has completed, but content is no longer specififed, this shoudln't hapen.");
			}
		}
		
		/**
		 * Stop and remove listeners from content  timer
		 */
		private function clearContentTimer():void
		{
			if( _contentTimer != null )
			{
				_contentTimer.stop();
				_contentTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, contentTimerComplete );
			}
		}

		private var _onFailure:Function;
		private var _shellApi:ShellApi;
		private var _island:String;
		private var _contentTimer:Timer;
		private var _currentContent:DLCContentData;
		private var _skipSecondaryContent:Boolean = false;
	}
}