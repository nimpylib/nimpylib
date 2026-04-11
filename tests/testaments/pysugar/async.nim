import pylib
pyimportAll asyncio
def main():
    async def main() -> float:
        async def f() -> float:
            return 1.2
        return await f()

    assert 1.2 == asyncio.run(main())

when not defined(nodejs): main()


