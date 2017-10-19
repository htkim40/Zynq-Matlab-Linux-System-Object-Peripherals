classdef base < matlab.System & matlab.system.mixin.Propagates &...
        coder.ExternalDependency & matlab.system.mixin.CustomIcon
    %  Open up a modem device (UART rs232) 
    %   Detailed explanation goes here
        
    properties (Hidden, Access = protected)
        % Uart port
        uart_port;
    end
    
    methods (Access = protected)
        function releaseImpl(obj)
            if coder.target('Rtw')
                coder.ceval('close_uart_RS232', obj.uart_port);
            end
        end
    end
    
    %% Execution Mode
    methods (Hidden, Static, Access = protected)
        function flag = showSimulateUsingImpl
            flag = false;
        end
        function simMode = getSimulateUsingImpl
            simMode = 'Interpreted execution';
        end
    end
    
    %% Helper
    methods (Hidden, Access = protected)
        function openRS232(obj)
            obj.uart_port = coder.nullcopy(int32(0));
            if coder.target('Rtw')
                coder.cinclude('rs232_include.h');        
                
                obj.uart_port = coder.ceval('open_uart_RS232');
                if (obj.uart_port < 0)
                    coder.ceval('exit', uint32(1));
                end 
            end
        end
        function s = ntstr(obj, in) %#ok<INUSL>
            s = coder.const([in char(0)]);
        end
    end
    
        %% External Dependency Methods
    methods (Static)
        function tf = isSupportedContext(bldCfg)
            % isSupportedContext Check if context is supported
            %
            % Determine if build context supports external dependency
            if bldCfg.isCodeGenTarget('rtw')
                tf = true;
            else
                error('RS232 is not supported for this platform');
            end
        end
        
        function updateBuildInfo(buildInfo,bldCfg)
            % updateBuildInfo update the build for code generation
            %
            % Add required source, include and linker files to the build
            
            rootDir = RTW.transformPaths(fileparts(strtok(mfilename('fullpath'),'+')));

            if bldCfg.isCodeGenTarget('rtw')
                % include libiio
                buildInfo.addIncludePaths(...
                    fullfile(rootDir, 'include'));
                buildInfo.addSourcePaths(...
                    fullfile(rootDir, 'src'));
                buildInfo.addSourceFiles({...
                    'rs232_API.c',...
                });
            end
        end
    end
    
end

